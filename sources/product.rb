require 'json'
require 'rest_client'

class Product < SourceAdapter
  def initialize(source) 
    @base = 'http://127.0.0.1:3000/products'
    # @base = 'http://rhostore.heroku.com/products'
    # @base = 'http://0.0.0.0:3000/products'
    super(source)
  end

  def login
    # TODO: Login to your data source here if necessary
  end

  def query(params=nil)
    # TODO: Query your backend data source and assign the records 
    # to a nested hash structure called @result. For example:
    # @result = { 
    #   "1"=>{"name"=>"Acme", "industry"=>"Electronics"},
    #   "2"=>{"name"=>"Best", "industry"=>"Software"}
    # }

    rest_result = RestClient.get("#{@base}.json").body

    if rest_result.code != 200
      raise SourceAdapterException.new("Error connecting!")
    end
    parsed = JSON.parse(rest_result)

    @result={}
    parsed.each do |item|
      # e.x. item = {"product"=>{"price"=>nil, "brand"=>"Rho2", "name"=>"Test2", "created_at"=>"2011-10-05T15:41:33Z", "quantity"=>nil, "updated_at"=>"2011-10-05T15:41:33Z", "id"=>75576, "sku"=>nil}}
      @result[item["product"]["id"].to_s] = item["product"]
    end if parsed 

  end
 
  def sync
    # Manipulate @result before it is saved, or save it 
    # yourself using the Rhoconnect::Store interface.
    # By default, super is called below which simply saves @result
    super
  end
 
  def create(create_hash)
 
    # e.x. create_hash = {"price"=>"30000", "name"=>"Lexus", "brand"=>"Toyota", "quantity"=>"1"}
    result = RestClient.post(@base, :product => create_hash)

    # After create we are redirected to the new record. 
    # The URL of the new record is given in the location header
    # e.x. http://rhostore.heroku.com/products/<id>.json
    location = "#{result.headers[:location]}.json"

    # We need to get the id of that record and return 
    # it as part of create so rhoconnect can establish a link 
    # from its temporary object on the client to this newly 
    # created object on the server

    new_record = RestClient.get(location).body
    JSON.parse(new_record)["product"]["id"].to_s

  end

  def update(update_hash)

    # e.x. update_hash: {"name"=>"Lexus ES", "id"=>"75694"}
    obj_id = update_hash['id']
    # We remove the 'id' because otherwise the server complains that there is no attribute 'id'
    update_hash.delete('id')   
    RestClient.put("#{@base}/#{obj_id}", :product => update_hash)

  end

  def delete(delete_hash)

    # e.x. delete_hash: {"brand"=>"apple", "price"=>"199", "name"=>"ipad", "created_at"=>"2011-09-28T16:21:06Z", "quantity"=>"", "updated_at"=>"2011-09-28T16:21:06Z", "id"=>"74484", "sku"=>""}
    RestClient.delete("#{@base}/#{delete_hash['id']}")
  end

  def logoff
    # TODO: Logout from the data source if necessary
  end
end
