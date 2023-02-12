module Capistrano
  class Anycable::Systemd < Capistrano::Plugin
    include AnycableCommon

    def register_hooks
      after 'deploy:finished', 'anycable:smart_restart'
    end

    def define_tasks
      eval_rakefile File.expand_path('../../tasks/systemd.rake', __FILE__)
    end

    def set_defaults
      set_if_empty :anycable_systemctl_bin, '/bin/systemctl'
      set_if_empty :anycable_service_unit_name, -> { "anycable_#{fetch(:application)}_#{fetch(:stage)}" }
      set_if_empty :anycable_enable_socket_service, -> { false }
      set_if_empty :anycable_systemctl_user, :system
      set_if_empty :anycable_enable_lingering, -> { fetch(:anycable_systemctl_user) != :system }
      set_if_empty :anycable_lingering_user, -> { fetch(:user) }
      set_if_empty :anycable_phased_restart, -> { false }
    end

    def expanded_bundle_command
      backend.capture(:echo, SSHKit.config.command_map[:bundle]).strip
    end

    def fetch_systemd_unit_path
      if fetch(:anycable_systemctl_user) == :system
        "/etc/systemd/system/"
      else
        home_dir = backend.capture :pwd
        File.join(home_dir, ".config", "systemd", "user")
      end
    end

    def systemd_command(*args)
      command = [fetch(:anycable_systemctl_bin)]

      unless fetch(:anycable_systemctl_user) == :system
        command << "--user"
      end

      command + args
    end

    def sudo_if_needed(*command)
      if fetch(:anycable_systemctl_user) == :system
        backend.sudo command.map(&:to_s).join(" ")
      else
        backend.execute(*command)
      end
    end

    def execute_systemd(*args)
      sudo_if_needed(*systemd_command(*args))
    end
  end
end
