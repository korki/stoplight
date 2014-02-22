#
# Stoplight Provider for GitHub (http://github.com)
#

module Stoplight::Providers
  class Github < Provider

    attr_reader :projects

    # Initializes a hash `@options` of default options
    def initialize(options = {})
      if options['url'].nil?
        raise ArgumentError, "'url' must be supplied as an option to the Provider. Please add 'url' => '...' to your hash."
      end

      @options = options
      add_options = {}

      if @options['access_token']
        add_options[:url_options] = {
          query: { access_token: @options['access_token'] }
        }
      end

      # load the data
      @projects ||= []
      @options['projects'].each do |project|
        add_options[:path] = build_path(project)
        response = load_server_data(add_options)
        if !response.nil? && !response.parsed_response.first.nil?
          resp = response.parsed_response.first
          @projects << Stoplight::Project.new(
            name: project,
            build_url: resp['target_url'],
            last_build_id: resp['id'],
            last_build_time: resp['updated_at'],
            last_build_status: state_to_int(resp['state']),
            current_status: current_state_to_int(resp['state'])
          )
        end
      end
    end

    def provider
      'github'
    end

    private

    def build_path(project)
      project_name = project.split('/', 2).first
      project_ref = project.split('/', 2).last
      "/repos/#{@options['account']}/#{project_name}/statuses/#{project_ref}"
    end

    def state_to_int(state)
      return 0 if state == 'success'
      return 2 if state == 'pending'
      1
    end

    def current_state_to_int(state)
      return 0 if state == 'success'
      return 1 if state == 'pending'
      -1
    end
  end
end
