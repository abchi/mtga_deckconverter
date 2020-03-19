require "yaml"
require "erb"
require "pg"

$dbconf = YAML.load(ERB.new(File.read("./database.yml")).result)["development"]
@database = PG::connect($dbconf)
