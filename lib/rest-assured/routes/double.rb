module RestAssured
  module DoubleRoutes
    def self.included(router)
      router.get '/' do
        redirect to('/doubles')
      end

      router.get '/doubles' do
        @doubles = Double.all
        haml :'doubles/index'
      end

      router.get '/doubles/new' do
        @double = Double.new
        haml :'doubles/new'
      end

      router.post '/doubles' do
        f = { :fullpath => params['fullpath'], :content => params['content'], :description => params['description'], :method => params['method'] }
        @double = Double.create(params['double'] || f)

        if browser?
          if @double.errors.blank?
            flash[:notice] = "Double created"
            redirect '/doubles'
          else
            flash[:error] = "Crumps! " + @double.errors.full_messages.join("; ")
            haml :'doubles/new'
          end
        else
          if @double.errors.present?
            status 400
            body @double.errors.full_messages.join("\n")
          end
        end
      end

      router.get %r{/doubles/(\d+)/edit} do |id|
        @double = Double.find(id)
        haml :'doubles/edit'
      end

      router.put %r{/doubles/(\d+)} do |id|
        @double = Double.find(id)

        if request.xhr?
          if params['active']
            @double.active = params['active']
            @double.save
            'Changed'
          end
        elsif params['double']
          @double.update_attributes(params['double'])

          if @double.save
            flash[:notice] = 'Double updated'
            redirect '/doubles'
          else
            flash[:error] = 'Crumps! ' + @double.errors.full_messages.join("\n")
            haml :'doubles/edit'
          end
        end
      end

      router.delete %r{/doubles/(\d+)} do |id|
        if Double.destroy(id)
          flash[:notice] = 'Double deleted'
          redirect '/doubles'
        end
      end

      router.delete '/doubles/all' do
        status Double.delete_all ? 200 : 500
      end
    end
  end
end