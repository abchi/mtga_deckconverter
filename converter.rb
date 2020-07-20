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
  blankline_count = 0
  @is_commander = false
  @is_companion = false
  deck_list.split("\r\n").each.with_index(1) do |file, i|
    if file == "" && blankline_count < 3 then
      return_data.push("\r\n")
      blankline_count += 1
      if blankline_count == 3 then
        is_commander = true
        is_companion = true
      end
    end
    if file == "Commander" then
        @is_commander = true
    elsif file == "Companion" then
        @is_companion = true
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
          if data[0] == "JMP" then
            data = jump_start(data)
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
  @is_deck = false
  if !text_file.empty? then
    if @is_commander == true then
      case lang
      when "en" then
        return_text = "Commander" + "\r\n"
      when "ja"
        return_text = "統率者" + "\r\n"
      end
    elsif @is_companion == true then
      case lang
      when "en" then
        return_text = "Companion" + "\r\n"
      when "ja"
        return_text = "相棒" + "\r\n"
      end
        @is_companion = false
    else
      case lang
      when "en" then
        return_text = "Deck" + "\r\n"
      when "ja"
        return_text = "デッキ" + "\r\n"
      end
        @is_deck = true
    end
    text_file.each do |line|
      if line != "\r\n" then
        case lang
        when "en" then
          input_text = "#{line[0]} #{line[3]} (#{line[1]}) #{line[2]}"
        when "ja" then
          input_text = "#{line[0]} #{line[4]} (#{line[1]}) #{line[2]}"
        end
          return_text += input_text + "\r\n"
      else
        return_text += "\r\n"
        if @is_companion == true then
          case lang
          when "en" then
            return_text += "Companion" + "\r\n"
          when "ja"
            return_text += "相棒" + "\r\n"
          end
            @is_companion = false
          elsif @is_deck == false then
            case lang
            when "en" then
              return_text += "Deck" + "\r\n"
            when "ja" then
              return_text += "デッキ" + "\r\n"
            end
              @is_deck = true
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

def jump_start(data)
  case data[1].to_i
  when 82
    card_no = 3
  when 86
    card_no = 310
  when 127
    card_no = 4
  when 167
    card_no = 48
  when 185
    card_no = 74
  when 230
    card_no = 80
  when 255
    card_no = 84
  when 270
    card_no = 137
  when 274
    card_no = 123
  when 278
    card_no = 57
  when 291
    card_no = 88
  when 302
    card_no = 152
  when 308
    card_no = 139
  when 319
    card_no = 121
  when 328
    card_no = 130
  when 342
    card_no = 152
  when 394
    card_no = 178
  when 428
    card_no = 173
  when 438
    card_no = 143
  end
  data[1] = card_no
  return data
end
