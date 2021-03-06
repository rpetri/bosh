require 'spec_helper'

describe Bosh::Director::Jobs::SnapshotDeployment do
  let(:deployment_manager) { double(BD::Api::DeploymentManager) }
  let(:deployment_name) { 'deployment' }
  let!(:deployment) { BDM::Deployment.make(name: deployment_name) }
  let!(:instance1) { BDM::Instance.make(deployment: deployment) }
  let!(:instance2) { BDM::Instance.make(deployment: deployment) }
  let!(:instance3) { BDM::Instance.make(deployment: deployment) }
  let!(:instance4) { BDM::Instance.make }

  subject { described_class.new(deployment_name) }

  before do
    BD::Api::DeploymentManager.stub(new: deployment_manager)
    deployment_manager.stub(find_by_name: deployment)
  end

  describe 'described_class.job_type' do
    it 'returns a symbol representing job type' do
      expect(described_class.job_type).to eq(:snapshot_deployment)
    end
  end

  context 'when snapshotting succeeds' do
    it 'should snapshot all instances in the deployment' do
      BD::Api::SnapshotManager.should_receive(:take_snapshot).with(instance1, {})
      BD::Api::SnapshotManager.should_receive(:take_snapshot).with(instance2, {})
      BD::Api::SnapshotManager.should_receive(:take_snapshot).with(instance3, {})
      BD::Api::SnapshotManager.should_not_receive(:take_snapshot).with(instance4, {})

      expect(subject.perform).to eq "snapshots of deployment 'deployment' created"
    end
  end

  context 'when snapshotting fails' do
    let(:nats) { double('NATS', publish: nil) }

    before do
      Bosh::Director::Config.stub(:nats).and_return(nats)
    end

    it 'should be shown in the status message' do
      BD::Api::SnapshotManager.should_receive(:take_snapshot).with(instance1, {}).and_raise(Bosh::Clouds::CloudError)
      BD::Api::SnapshotManager.should_receive(:take_snapshot).with(instance2, {})
      BD::Api::SnapshotManager.should_receive(:take_snapshot).with(instance3, {}).and_raise(Bosh::Clouds::CloudError)

      expect(subject.perform).to eq "snapshots of deployment 'deployment' created, with 2 failure(s)"
    end

    it 'should send an alert on the message bus' do
      exception = Bosh::Clouds::CloudError.new('a helpful message')

      nats.should_receive(:publish).with do |subject, message|
        expect(subject).to eq 'hm.director.alert'
        payload = JSON.parse(message)
        expect(payload['summary']).to include 'a helpful message'
        expect(payload['summary']).to include 'CloudError'
      end

      BD::Api::SnapshotManager.should_receive(:take_snapshot).with(instance1, {}).and_raise(exception)
      BD::Api::SnapshotManager.should_receive(:take_snapshot).with(instance2, {})
      BD::Api::SnapshotManager.should_receive(:take_snapshot).with(instance3, {})

      subject.perform
    end

    it 'logs the cause of failure' do
      exception = Bosh::Clouds::CloudError.new('a helpful message')
      BD::Api::SnapshotManager.should_receive(:take_snapshot).with(instance1, {}).and_raise(exception)
      BD::Api::SnapshotManager.should_receive(:take_snapshot).with(instance2, {})
      BD::Api::SnapshotManager.should_receive(:take_snapshot).with(instance3, {})

      Bosh::Director::Config.logger.should_receive(:error).with do |message|
        expect(message).to include("#{instance1.job}/#{instance1.index}")
        expect(message).to include(instance1.vm.cid)
        expect(message).to include('a helpful message')
      end

      subject.perform
    end
  end

  describe '#send_alert' do
    let(:job) { "job" }
    let(:index) { 0 }
    let(:fake_instance) { double("fake instance", job: job, index: index) }
    let(:fake_nats) { double("nats") }

    it 'sends an alert over NATS on hm.director.alert' do
      fake_nats.should_receive(:publish).with('hm.director.alert', json_match(
          eq(
              {
                  "id" => 'director',
                  'severity' => 3,
                  'title' => "director - snapshot failure",
                  'summary' => "failed to snapshot #{job}/#{index}: hello",
                  'created_at' => anything,
              }
          ))
      )

      Bosh::Director::Config.stub(:nats => fake_nats)
      subject.send_alert(fake_instance, 'hello')
    end
  end
end
