module OmniAuth
  module Strategies
    class Shibboleth
      include OmniAuth::Strategy
      
      option :shib_session_id_field, 'Shib-Session-ID'
      option :shib_application_id_field, 'Shib-Application-ID'
      option :uid_field, 'eppn'
      option :name_field, 'displayName'
      option :info_fields, {:email => 'mail'}
      option :extra_fields, []
      option :debug, false

      def self.login_path(host)
        "/Shibboleth.sso/Login?target=https://#{host}/auth/shibboleth/callback"
      end

      def self.login_path_with_entity(host, entity)
        "/Shibboleth.sso/Login?target=#{self.return_target(host)}&entityID=#{self.shibboleth_entity_id(entity)}"
      end

      def self.return_target(host)
        CGI.escape("https://#{host}/auth/shibboleth/callback")
      end

      def self.shibboleth_entity_id(entity)
        CGI.escape(entity)
      end
      
      def request_phase
        [
            302,
            {
                'Location' => script_name + callback_path + query_string,
                'Content-Type' => 'text/plain'
            },
            ["You are being redirected to Shibboleth SP/IdP for sign-in."]
        ]
      end

      def callback_phase
        if options[:debug]
          # dump attributes
          return [
            200,
            {
              'Content-Type' => 'text/plain'
            },
            ["!!!!! This message is generated by omniauth-shibboleth. To remove it set :debug to false. !!!!!\n#{request.env.sort.map {|i| "#{i[0]}: #{i[1]}" }.join("\n")}"]
          ]
        end
        return fail!(:no_shibboleth_session) unless (get_attribute(options.shib_session_id_field.to_s) || get_attribute(options.shib_application_id_field.to_s))
        super
      end

      def get_attribute(name)
        request.env[header_name(name)]
      end

      def header_name(name)
        corrected_name = name.gsub('-', '_').upcase!
        "HTTP_#{corrected_name}"
      end

      uid do
        get_attribute(options.uid_field.to_s)
      end

      info do
        res = {
          :name  => get_attribute(options.name_field.to_s)
        }
        options.info_fields.each_pair do |k,v|
          res[k] = get_attribute(v.to_s)
        end
        res
      end

      extra do
        options.extra_fields.inject({:raw_info => {}}) do |hash, field|
          hash[:raw_info][field] = get_attribute(field.to_s)
          hash
        end
      end

    end
  end
end
