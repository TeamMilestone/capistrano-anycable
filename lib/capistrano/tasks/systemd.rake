# frozen_string_literal: true

git_plugin = self

namespace :anycable do
  namespace :systemd do
    desc 'Config Anycable systemd service'
    task :config do
      on roles(fetch(:anycable_role)) do |role|

        upload_compiled_template = lambda do |template_name, unit_filename|
          git_plugin.template_anycable template_name, "#{fetch(:tmp_dir)}/#{unit_filename}", role
          systemd_path = fetch(:anycable_systemd_conf_dir, git_plugin.fetch_systemd_unit_path)
          if fetch(:anycable_systemctl_user) == :system
            sudo "mv #{fetch(:tmp_dir)}/#{unit_filename} #{systemd_path}"
          else
            execute :mkdir, "-p", systemd_path
            execute :mv, "#{fetch(:tmp_dir)}/#{unit_filename}", "#{systemd_path}"
          end
        end

        upload_compiled_template.call("anycable.service", "#{fetch(:anycable_service_unit_name)}.service")

        if fetch(:anycable_enable_socket_service)
          upload_compiled_template.call("anycable.socket", "#{fetch(:anycable_service_unit_name)}.socket")
        end

        # Reload systemd
        git_plugin.execute_systemd("daemon-reload")
      end
    end

    desc 'Generate service configuration locally'
    task :generate_config_locally do
      fake_role = Struct.new(:hostname)
      run_locally do
        File.write('anycable.service', git_plugin.compiled_template_anycable("anycable.service", fake_role.new("example.com")).string)
        if fetch(:anycable_enable_socket_service)
          File.write('anycable.socket', git_plugin.compiled_template_anycable("anycable.socket", fake_role.new("example.com")).string)
        end
      end
    end

    desc 'Enable Anycable systemd service'
    task :enable do
      on roles(fetch(:anycable_role)) do
        git_plugin.execute_systemd("enable", fetch(:anycable_service_unit_name))
        git_plugin.execute_systemd("enable", fetch(:anycable_service_unit_name) + ".socket") if fetch(:anycable_enable_socket_service)

        if fetch(:anycable_systemctl_user) != :system && fetch(:anycable_enable_lingering)
          execute :loginctl, "enable-linger", fetch(:anycable_lingering_user)
        end
      end
    end

    desc 'Disable Anycable systemd service'
    task :disable do
      on roles(fetch(:anycable_role)) do
        git_plugin.execute_systemd("disable", fetch(:anycable_service_unit_name))
        git_plugin.execute_systemd("disable", fetch(:anycable_service_unit_name) + ".socket") if fetch(:anycable_enable_socket_service)
      end
    end

    desc 'Stop Anycable socket via systemd'
    task :stop_socket do
      on roles(fetch(:anycable_role)) do
        git_plugin.execute_systemd("stop", fetch(:anycable_service_unit_name) + ".socket")
      end
    end

    desc 'Restart Anycable socket via systemd'
    task :restart_socket do
      on roles(fetch(:anycable_role)) do
        git_plugin.execute_systemd("restart", fetch(:anycable_service_unit_name) + ".socket")
      end
    end
  end

  desc 'Start Anycable service via systemd'
  task :start do
    on roles(fetch(:anycable_role)) do
      git_plugin.execute_systemd("start", fetch(:anycable_service_unit_name))
    end
  end

  desc 'Stop Anycable service via systemd'
  task :stop do
    on roles(fetch(:anycable_role)) do
      git_plugin.execute_systemd("stop", fetch(:anycable_service_unit_name))
    end
  end

  desc 'Restarts or reloads Anycable service via systemd'
  task :smart_restart do
    if fetch(:anycable_phased_restart)
      invoke 'anycable:reload'
    else
      invoke 'anycable:restart'
    end
  end

  desc 'Restart Anycable service via systemd'
  task :restart do
    on roles(fetch(:anycable_role)) do
      git_plugin.execute_systemd("restart", fetch(:anycable_service_unit_name))
    end
  end

  desc 'Reload Anycable service via systemd'
  task :reload do
    on roles(fetch(:anycable_role)) do
      service_ok = if fetch(:anycable_systemctl_user) == :system
        execute("#{fetch(:anycable_systemctl_bin)} status #{fetch(:anycable_service_unit_name)} > /dev/null", raise_on_non_zero_exit: false)
      else
        execute("#{fetch(:anycable_systemctl_bin)} --user status #{fetch(:anycable_service_unit_name)} > /dev/null", raise_on_non_zero_exit: false)
      end
      cmd = 'reload'
      if !service_ok
        cmd = 'restart'
      end
      if fetch(:anycable_systemctl_user) == :system
        sudo "#{fetch(:anycable_systemctl_bin)} #{cmd} #{fetch(:anycable_service_unit_name)}"
      else
        execute "#{fetch(:anycable_systemctl_bin)}", "--user", cmd, fetch(:anycable_service_unit_name)
      end
    end
  end

  desc 'Get Anycable service status via systemd'
  task :status do
    on roles(fetch(:anycable_role)) do
      git_plugin.execute_systemd("status", fetch(:anycable_service_unit_name))
      git_plugin.execute_systemd("status", fetch(:anycable_service_unit_name) + ".socket") if fetch(:anycable_enable_socket_service)
    end
  end
end
