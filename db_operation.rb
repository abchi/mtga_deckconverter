require "bundler/setup"
Bundler.require
require "yaml"
require "erb"

if development? then
    dbconf = YAML.load(ERB.new(File.read("./database.yml")).result)["development"]
else
    dbconf = YAML.load(ERB.new(File.read("./database.yml")).result)["production"]
end
@database = PG::connect(dbconf)

def insert_db(insert_data)
    insert_data.each do |data|
        sql = "SELECT * FROM card_m WHERE set = $1 AND number = $2"
        execute_data = @database.exec(sql, [data[:set], data[:number]]).values
        if execute_data.empty? then
            puts "#{data[:set]} #{data[:number]} ==> 未登録。登録処理を行います。"
            begin
                sql = "INSERT INTO card_m(set, number, name_en, name_ja, isvalid) VALUES($1, $2, $3, $4, $5)"
                @database.exec(sql, [data[:set], data[:number], data[:name_en], data[:name_ja], 1])
            rescue => error
                puts error
            end
        else
            puts "#{data[:set]} #{data[:number]} ==> 登録済み。"
            if execute_data[0][2] == data[:name_en] && execute_data[0][3] == data[:name_ja] then
                puts "内容変更無し。更新しません。"
            elsif data[:name_en] == "" || data[:name_ja] == "" then
                puts "更新データが入っていません。更新しません。"
            else
                begin
                    puts "内容変更有り。更新します。"
                    sql = "UPDATE card_m SET name_en = $1, name_ja = $2 WHERE set = $3 AND number = $4"
                    @database.exec(sql, [data[:name_en], data[:name_ja], data[:set], data[:number]])
                rescue => error
                    puts error
                end
            end
        end
    end
end

def mtg_cards(set)
    return_data = Array.new
    hash = Hash.new
    if set.empty? then
        cards = MTG::Card.all
    else
        cards = MTG::Card.where(set: set).where(orderBy: "number").all
    end
    cards.each do |card|
        if card.type.include? "Adventure" then
        else
            if card.layout == "split" then
                if hash[:number] == card.number then
                    if card.names[0] == card.name then
                        hash.store(:name_en, card.name + " // " + hash[:name_en])
                    else
                        hash.store(:name_en, hash[:name_en] + " // " + card.name)
                    end
                else
                    hash.store(:name_en, card.name)
                end
            else
                hash.store(:name_en, card.name)
            end
            if card.foreign_names.empty? then
                name = ""
                hash.store(:name_ja, name)
            else
                card.foreign_names.each do |foreign_name|
                    if foreign_name.language == "Japanese" then
                        if hash[:number] == card.number && card.layout == "split" then
                            if card.names[0] == card.name then
                                hash.store(:name_ja, foreign_name.name + " // " + hash[:name_ja])
                            else
                                hash.store(:name_ja, hash[:name_ja] + " // " + foreign_name.name)
                            end
                        else
                            hash.store(:name_ja, foreign_name.name)
                        end
                    end
                end
            end
            # DOMはMTGAではDARになっているので変換
            if card.set == "DOM" then
                card_set = "DAR"
            else
                card_set = card.set
            end
            hash.store(:set, card_set)
            hash.store(:number, card.number)
            if hash[:name_ja].empty? then
                hash.store(:name_ja, "")
            end
            tmp = Marshal.dump(hash)
            insert_hash = Marshal.load(tmp)
            return_data.push(insert_hash)
        end
    end
    return return_data
end

# name_jaが入っていないデータの更新用
def name_ja_patch()
    begin
        sql = "SELECT * FROM card_m WHERE name_ja = $1 ORDER BY set, number"
        execute_data = @database.exec(sql, [""]).values
        execute_data.each do |data|
            name_en = data[2]
            sql = "SELECT name_ja FROM card_m WHERE name_en = $1 AND name_ja != '' LIMIT 1"
            card_name = @database.exec(sql, [name_en]).values[0]
            if card_name.nil? then
                sql = "SELECT name_ja FROM patch_d WHERE name_en = $1"
                card_name = @database.exec(sql, [name_en]).values[0]
            end
            card_name = [""] if card_name.nil?
            sql = "UPDATE card_m SET name_ja = $1 WHERE set = $2 AND number = $3"
            @database.exec(sql, [card_name[0], data[0], data[1]])
        end
    rescue => error
        puts error
    end
end

def insert_data(set_name)
    data = mtg_cards(set_name)
    data.sort_by! {|a| a[:number].to_i}
    insert_db(data)
end
