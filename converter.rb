require "bundler/setup"
Bundler.require
require "yaml"
require "erb"

if development? then
    $dbconf = YAML.load(ERB.new(File.read("./database.yml")).result)["development"]
else
    $dbconf = YAML.load(ERB.new(File.read("./database.yml")).result)["production"]
end
@database = PG::connect($dbconf)

def read_deck_list(deck_list)
    return_data = Array.new
    is_blankline = false
    @is_brawl = false
    deck_list.split("\r\n").each.with_index(1) do |file, i|
        if file == "" && is_blankline == false then
            return_data.push("\n")
            is_blankline = true
        end
        if file == "Commander" || (file == "" && i == 2) then
            @is_brawl = true
        end
        file.each_line do |line|
            line.chomp!
            if line == "Sideboard" then
            elsif line != "" then
                index_card_first = line.index(" ")
                index_card_end = line.index(" (")
                if index_card_first.nil? then
                    break
                end
                if index_card_end.nil? then
                    card_name = line[index_card_first + 1..-1]
                else
                    card_name = line[index_card_first + 1..index_card_end - 1]
                end

                card_name.gsub!("　", " ")
                card_name.gsub!(" ", "")

                # /の数は2つにする。MTGAの分割カード名称には/が2つ付いている。
                card_name.gsub!(/\/{1,}/, "//")

                card_count = line[0...index_card_first]
                sql = "SELECT * FROM card_m WHERE (REPLACE(name_en, ' ', '') = $1 OR REPLACE(name_ja, ' ', '') = $2) AND isvalid = 1 ORDER BY RANDOM() LIMIT 1"
                begin
                    data = @database.exec(sql, [card_name, card_name])[0].values
                    if data.empty? then
                        break
                    end
                    data.unshift(card_count)
                    return_data.push(data)
                rescue => error
                    puts error
                end
            else
                return_data.push("\n")
            end
        end
    end
    return return_data
end

def text_conversion(text_file, lang)
    return_text = String.new
    if !text_file.empty? then
        if @is_brawl == true then
            case lang
            when "en" then
                return_text = "Commander" + "\r\n"
            when "ja"
                return_text = "統率者" + "\r\n"
            end
        else
            case lang
            when "en" then
                return_text = "Deck" + "\r\n"
            when "ja"
                return_text = "デッキ" + "\r\n"
            end    
        end
        text_file.each do |line|
            if line != "\n" then
                case lang
                when "en" then
                    input_text = "#{line[0]} #{line[3]} (#{line[1]}) #{line[2]}"
                when "ja" then
                    input_text = "#{line[0]} #{line[4]} (#{line[1]}) #{line[2]}"
                end
                return_text += input_text + "\r\n"
            else
                return_text += "\r\n"
                if @is_brawl == true then
                    case lang
                    when "en" then
                        return_text += "Deck" + "\r\n"
                    when "ja"
                        return_text += "デッキ" + "\r\n"
                    end
                else
                    case lang
                    when "en" then
                        return_text += "Sideboard" + "\r\n"
                    when "ja" then
                        return_text += "サイドボード" + "\r\n"
                    end
                end
            end
        end
    end
    return return_text
end
