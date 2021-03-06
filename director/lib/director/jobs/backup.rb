module Bosh::Director
  module Jobs
    class Backup < BaseJob
      @queue = :normal

      def self.job_type
        :bosh_backup
      end

      def initialize(dest_dir, options = {})
        @dest_dir = dest_dir
        @tar_gzipper = options.fetch(:tar_gzipper) { TarGzipper.new }
        @blobstore_client = options.fetch(:blobstore) { App.instance.blobstores.blobstore }
        @db_adapter = options.fetch(:db_adapter) { Bosh::Director::DbBackup.create(Config.db_config) }
      end

      def perform
        Dir.mktmpdir(nil, @dest_dir) do |tmpdir|

          event_log.begin_stage('Backing up director', 3)

          files = []

          files << backup_logs(tmpdir)
          files << backup_task_logs(tmpdir)
          files << backup_database(tmpdir)

          begin
            files << backup_blobstore(tmpdir)
          rescue Bosh::Blobstore::NotImplemented
            logger.warn('Skipping blobstore backup because blobstore client does not support list operation')
          end

          backup_file = "#{@dest_dir}/backup.tgz"
          @tar_gzipper.compress(files, backup_file)

          "Backup created at #{backup_file}"
        end
      end

      def backup_logs(tmpdir)
        output = "#{tmpdir}/logs.tgz"

        track_and_log('Backing up logs') do
          @tar_gzipper.compress('/var/vcap/sys/log', output)
        end

        output
      end

      def backup_task_logs(tmpdir)
        output = "#{tmpdir}/task_logs.tgz"

        track_and_log('Backing up task logs') do
          @tar_gzipper.compress('/var/vcap/store/director/tasks', output)
        end

        output
      end

      def backup_database(tmpdir)
        output = "#{tmpdir}/director_db.sql"

        track_and_log('Backing up database') do
          @db_adapter.export(output)
        end

        output
      end

       # raises NotImplemented if the blobstore client doesn't support list()
      def backup_blobstore(tmpdir)
        blobs_dir = "#{tmpdir}/blobs"
        output = "#{tmpdir}/blobs.tgz"

        Dir.mkdir(blobs_dir)

        track_and_log('Backing up blobstore') do
          files = @blobstore_client.list

          files.each do |file_id|
            File.open("#{blobs_dir}/#{file_id}", 'w') do |file|
              logger.debug("Writing file #{file.path}")
              @blobstore_client.get(file_id, file)
            end
          end
        end

        @tar_gzipper.compress(blobs_dir, output)

        output
      end
    end
  end
end
