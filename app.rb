require "bundler/setup"
Bundler.require
require "sinatra/reloader" if development?
require "yaml"
require "./converter.rb"

title = "MTG ARENA DECK CONVERTER"

get "/" do
    @title = title
    @database = PG::connect($dbconf)
    @input_list = ""
    @output_list = ""
    erb :mtga_deck_converter, :layout => :layout
end

post "/" do
    @title = title
    @database = PG::connect($dbconf)
    @input_list = params[:input_list]
    @output_list = text_conversion(read_deck_list(params[:input_list]), "ja")
    erb :mtga_deck_converter, :layout => :layout
end
