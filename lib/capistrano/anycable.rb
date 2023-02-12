require 'capistrano/bundler'
require 'capistrano/plugin'

module Capistrano
  module AnycableCommon
    def compiled_template_anycable(from, role)
      @role = role
      file = [
          "lib/capistrano/templates/#{from}-#{role.hostname}-#{fetch(:stage)}.rb",
          "lib/capistrano/templates/#{from}-#{role.hostname}.rb",
          "lib/capistrano/templates/#{from}-#{fetch(:stage)}.rb",
          "lib/capistrano/templates/#{from}.rb.erb",
          "lib/capistrano/templates/#{from}.rb",
          "lib/capistrano/templates/#{from}.erb",
          "config/deploy/templates/#{from}.rb.erb",
          "config/deploy/templates/#{from}.rb",
          "config/deploy/templates/#{from}.erb",
          File.expand_path("../templates/#{from}.erb", __FILE__),
          File.expand_path("../templates/#{from}.rb.erb", __FILE__)
      ].detect { |path| File.file?(path) }
      erb = File.read(file)
      StringIO.new(ERB.new(erb, trim_mode: '-').result(binding))
    end

    def template_anycable(from, to, role)
      backend.upload! compiled_template_anycable(from, role), to
    end
  end

  class Anycable < Capistrano::Plugin
    include AnycableCommon

    def set_defaults
      set_if_empty :anycable_role, :web
      set_if_empty :anycable_env, -> { fetch(:rack_env, fetch(:rails_env, fetch(:stage))) }
      set_if_empty :anycable_access_log, -> { File.join(shared_path, 'log', "anycable.log") }
      set_if_empty :anycable_error_log, -> { File.join(shared_path, 'log', "anycable.log") }

      # Chruby, Rbenv and RVM integration
      append :chruby_map_bins, 'anycable', 'anycablectl' if fetch(:chruby_map_bins)
      append :rbenv_map_bins, 'anycable', 'anycablectl' if fetch(:rbenv_map_bins)
      append :rvm_map_bins, 'anycable', 'anycablectl' if fetch(:rvm_map_bins)

      # Bundler integration
      append :bundle_bins, 'anycable', 'anycablectl'
    end
  end
end

require 'capistrano/anycable/systemd'
