require 'erubis'

module RestAssured
  class Response

    def self.perform(app)
      request = app.request
      if d = Models::Double.where(:fullpath => request.fullpath, :active => true, :verb => request.request_method).first
        return_double app, d
      elsif redirect_url = Models::Redirect.find_redirect_url_for(request.fullpath)
        if d = Models::Double.where(:fullpath => redirect_url, :active => true, :verb => request.request_method).first
          return_double app, d
        else
          app.redirect redirect_url
        end
      else
        app.status 404
      end
    end

    def self.return_double(app, d)
      request = app.request
      request.body.rewind
      body = request.body.read #without temp variable ':body = > body' is always nil. mistery
      env  = request.env.except('rack.input', 'rack.errors', 'rack.logger')

      d.increment!(:request_count)

      if d.template_type == "custom"
        response_params = {"request_count" => d.request_count}
        response_body = d.content.nil? ? "" : d.content.gsub(":::request_count", d.request_count.to_s)
      elsif d.template_type == "erubis"
        response_params = {"request_count" => d.request_count}
        scope_params = response_params.merge({:double => d, :request_body => body})
        response_body = d.content.nil? ? "" : Erubis::Eruby.new(d.content).result(scope_params)
      else
        response_params = {}
        response_body = d.content
      end

      d.requests.create!(
        :rack_env => env.to_json,
        :body => body,
        :params => request.params.to_json,
        :response_body => response_body,
        :response_params => response_params.to_json
      )

      app.headers d.response_headers
      app.body response_body
      app.status d.status
    end

  end
end
