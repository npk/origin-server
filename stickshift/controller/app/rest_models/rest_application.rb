class RestApplication < StickShift::Model
  attr_accessor :framework, :creation_time, :uuid, :embedded, :aliases, :name, :gear_count, :links, :domain_id, :git_url, :app_url, :ssh_url
  
  def initialize(app, url, nolinks=false)
    self.embedded = []
    app.requires(true).each do |feature|
      cart = CartridgeCache.find_cartridge(feature)
      if cart.categories.include? "web_framework"
        self.framework = feature
      else
        self.embedded << feature
      end
    end

    self.name = app.name
    self.creation_time = app.created_at
    self.uuid = app._id.to_s
    self.aliases = app.aliases
    self.gear_count = app.num_gears
    self.domain_id = app.domain.namespace

    #self.gear_profile = app.node_profile
    #self.scalable = app.scalable
    #self.scale_min,self.scale_max = app.scaling_limits

    self.git_url = "ssh://#{app.ssh_uri}/~/git/#{@name}.git/"
    self.app_url = "http://#{app.fqdn}/"
    self.ssh_url = "ssh://#{app.ssh_uri}"

    #self.health_check_path = app.health_check_path
    cart_type = "embedded"
    cache_key = "cart_list_#{cart_type}"
    
    unless nolinks
      carts = nil
      #if app.scalable
      #  carts = Application::SCALABLE_EMBEDDED_CARTS
      #else
        carts = CacheHelper.get_cached(cache_key, :expires_in => 21600.seconds) do
          CartridgeCache.find_cartridge_by_category("embedded")
        end
      #end
      # Update carts list
      # - remove already embedded carts
      # - remove conflicting carts
      #app.embedded.keys.each do |cname|
      #  carts -= [cname]
      #  cinfo = CartridgeCache.find_cartridge(cname)
      #  carts -= cinfo.conflicts_feature if defined?(cinfo.conflicts_feature)
      #end if !app.embedded.empty?

      self.links = {
        "GET" => Link.new("Get application", "GET", URI::join(url, "domains/#{@domain_id}/applications/#{@name}")),
        "GET_DESCRIPTOR" => Link.new("Get application descriptor", "GET", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/descriptor")),      
        "GET_GEARS" => Link.new("Get application gears", "GET", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/gears")),      
        "GET_GEAR_GROUPS" => Link.new("Get application gear groups", "GET", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/gear_groups")),      
        "START" => Link.new("Start application", "POST", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/events"), [
          Param.new("event", "string", "event", "start")
        ]),
        "STOP" => Link.new("Stop application", "POST", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/events"), [
          Param.new("event", "string", "event", "stop")
        ]),      
        "RESTART" => Link.new("Restart application", "POST", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/events"), [
          Param.new("event", "string", "event", "restart")
        ]),
        "FORCE_STOP" => Link.new("Force stop application", "POST", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/events"), [
          Param.new("event", "string", "event", "force-stop")
        ]),
        "EXPOSE_PORT" => Link.new("Expose port", "POST", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/events"), [
          Param.new("event", "string", "event", "expose-port")
        ]),
        "CONCEAL_PORT" => Link.new("Conceal port", "POST", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/events"), [
          Param.new("event", "string", "event", "conceal-port")
        ]),
        "SHOW_PORT" => Link.new("Show port", "POST", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/events"), [
          Param.new("event", "string", "event", "show-port")
        ]),
        "ADD_ALIAS" => Link.new("Add application alias", "POST", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/events"), [
          Param.new("event", "string", "event", "add-alias"),
          Param.new("alias", "string", "The server alias for the application")
        ]),
        "REMOVE_ALIAS" => Link.new("Remove application alias", "POST", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/events"), [
          Param.new("event", "string", "event", "remove-alias"),
          Param.new("alias", "string", "The application alias to be removed")
        ]),
        "SCALE_UP" => Link.new("Scale up application", "POST", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/events"), [
          Param.new("event", "string", "event", "scale-up")
        ]),
        "SCALE_DOWN" => Link.new("Scale down application", "POST", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/events"), [
          Param.new("event", "string", "event", "scale-down")
        ]),
        "DELETE" => Link.new("Delete application", "DELETE", URI::join(url, "domains/#{@domain_id}/applications/#{@name}")),
        
        "ADD_CARTRIDGE" => Link.new("Add embedded cartridge", "POST", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/cartridges"),[
          Param.new("cartridge", "string", "framework-type, e.g.: mongodb-2.0", carts)
        ]),
        "LIST_CARTRIDGES" => Link.new("List embedded cartridges", "GET", URI::join(url, "domains/#{@domain_id}/applications/#{@name}/cartridges"))
      }
    end
  end
  
  def to_xml(options={})
    options[:tag_name] = "application"
    super(options)
  end
end