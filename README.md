![Build Status](https://travis-ci.org/square/etre-client-ruby.svg?branch=master)

Description
------
etre-client is a client gem for [Etre](https://github.com/square/etre).

Installation
------
etre-client is hosted on rubygems.org. To install it
1. Add "etre-client" to your Gemfile
2. Run "bundle install"

Alternatively, you can just "gem install etre-client".

Usage
------
Require the gem
```
require 'etre-client'
```

Create a new client
```
e = Etre::Client.new(entity_type: "node", url: "http://127.0.0.1:8080", ssl_cert: nil, ssl_key: nil, ssl_ca: nil, insecure: true)
```

Insert entities
```
entities = [{"foo" => "bar"}, {"foo" => "abc"}, {"l1" => "a", "l2" => "b"}]
e.insert(entities)
=> [{"id"=>"59f90caadd1b176f02eddcd8", "uri"=>"127.0.0.1:8080/api/v1/entity/59f90caadd1b176f02eddcd8"}, {"id"=>"59f90caadd1b176f02eddcda", "uri"=>"127.0.0.1:8080/api/v1/entity/59f90caadd1b176f02eddcda"}, {"id"=>"59f90e3fdd1b176f02eddce5", "uri"=>"127.0.0.1:8080/api/v1/entity/59f90e3fdd1b176f02eddce5"}]
```

Read entities
```
query = "foo=bar"
e.query(query)
=> [{"_id"=>"59f90caadd1b176f02eddcd8", "_rev"=>0, "_type"=>"node", "foo"=>"bar"}]
```

Update entities
```
query = "foo=bar"
patch = {"foo" => "newbar"}
e.update(query, patch)
=> [{"id"=>"59f90caadd1b176f02eddcd8", "uri"=>"127.0.0.1:8080/api/v1/entity/59f90caadd1b176f02eddcd8", "diff"=>{"_id"=>"59f90caadd1b176f02eddcd8", "_rev"=>0, "_type"=>"node", "foo"=>"bar"}}]
```

Update a single entity
```
id = "59f90caadd1b176f02eddcda"
patch = {"foo" => "slug"}
e.update_one(id, patch)
=> {"id"=>"59f90caadd1b176f02eddcda", "uri"=>"127.0.0.1:8080/api/v1/entity/59f90caadd1b176f02eddcda", "diff"=>{"_id"=>"59f90caadd1b176f02eddcda", "_rev"=>0, "_type"=>"node", "foo"=>"abc"}}
```

Delete entities
```
query = "foo=slug"
e.delete(query)
=> [{"id"=>"59f90caadd1b176f02eddcda", "uri"=>"127.0.0.1:8080/api/v1/entity/59f90caadd1b176f02eddcda", "diff"=>{"_id"=>"59f90caadd1b176f02eddcda", "_rev"=>1, "_type"=>"node", "foo"=>"slug"}}]
```

Delete a single entity
```
id = "59f90caadd1b176f02eddcd8"
e.delete_one(id)
=> {"id"=>"59f90caadd1b176f02eddcd8", "uri"=>"127.0.0.1:8080/api/v1/entity/59f90caadd1b176f02eddcd8", "diff"=>{"_id"=>"59f90caadd1b176f02eddcd8", "_rev"=>1, "_type"=>"node", "foo"=>"newbar"}}
```

List the labels for an entity
```
id = "59f90e3fdd1b176f02eddce5"
e.labels(id)
=> ["f1", "f2"]
```

Delete the label on an entity
```
id = "59f90e3fdd1b176f02eddce5"
label = "l1"
e.delete_label(id)
=> {"id"=>"59f90e3fdd1b176f02eddce5", "uri"=>"127.0.0.1:8080/api/v1/entity/59f90e3fdd1b176f02eddce5", "diff"=>{"_id"=>"59f90e3fdd1b176f02eddce5", "_rev"=>0, "_type"=>"node", "l1"=>"a", "l2"=>"b"}}
```

Development
------
Run the tests
```
bundle exec rake spec
```

## License

Copyright (c) 2017 Square Inc. Distributed under the Apache 2.0 License.
See LICENSE file for further details.
