require 'bundler/setup'
Bundler.require
require 'yaml'
require 'erb'

if development?
  $dbconf = YAML.load(ERB.new(File.read('./database.yml')).result)['development']
else
  $dbconf = YAML.load(ERB.new(File.read('./database.yml')).result)['production']
end
@database = PG::connect($dbconf)

def read_deck_list(deck_list)
  return_data = Array.new
  blankline_count = 0
  @is_commander = false
  @is_companion = false
  deck_list.split("\r\n").each.with_index(1) do |file, i|
    if file == '' && blankline_count < 3
      return_data.push("\r\n")
      blankline_count += 1
      if blankline_count == 3
        @is_commander = true
        @is_companion = true
      end
    end
    if file == 'Commander'
      @is_commander = true
    elsif file == 'Companion'
      @is_companion = true
    end

    file.each_line do |line|
      line.chomp!
      if line == 'Sideboard'
        nil
      elsif line != ''
        index_card_first = line.index(' ')
        index_card_end = line.index(' (')

        break if index_card_first.nil?

        if index_card_end.nil?
          card_name = line[index_card_first + 1..-1]
        else
          card_name = line[index_card_first + 1..index_card_end - 1]
        end

        card_name.gsub!('　', ' ')
        card_name.gsub!(' ', '')

        card_count = line[0...index_card_first]
        sql = "SELECT set, collector_number, text_en, text_ja FROM card_m WHERE (REPLACE(text_en, ' ', '') = $1 OR REPLACE(text_ja, ' ', '') = $2) AND isvalid = 1 ORDER BY RANDOM() LIMIT 1"
        begin
          data = @database.exec(sql, [card_name, card_name])[0].values

          break if data.empty?
          data = jump_start(data) if data[0] == 'JMP'

          data[1] = data[1].to_i
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
  return_data
end

def text_conversion(text_file, lang)
  return_text = String.new
  @is_deck = false
  unless text_file.empty?
    if @is_commander
      case lang
      when 'en'
        return_text = 'Commander' + "\r\n"
      when 'ja'
        return_text = '統率者' + "\r\n"
      end
    elsif @is_companion
      case lang
      when 'en'
        return_text = 'Companion' + "\r\n"
      when 'ja'
        return_text = '相棒' + "\r\n"
      end
      @is_companion = false
    else
      case lang
      when 'en'
        return_text = 'Deck' + "\r\n"
      when 'ja'
        return_text = 'デッキ' + "\r\n"
      end
      @is_deck = true
    end
    text_file.each do |line|
      if line != "\r\n"
        case lang
        when 'en'
          input_text = "#{line[0]} #{line[3]} (#{line[1]}) #{line[2]}"
        when 'ja'
          input_text = "#{line[0]} #{line[4]} (#{line[1]}) #{line[2]}"
        end
        return_text += input_text + "\r\n"
      else
        return_text += "\r\n"
        if @is_companion
          case lang
          when 'en'
            return_text += 'Companion' + "\r\n"
          when 'ja'
            return_text += '相棒' + "\r\n"
          end
          @is_companion = false
        elsif !@is_deck
          case lang
          when 'en'
            return_text += 'Deck' + "\r\n"
          when 'ja'
            return_text += 'デッキ' + "\r\n"
          end
          @is_deck = true
        else
          case lang
          when 'en'
            return_text += 'Sideboard' + "\r\n"
          when 'ja'
            return_text += 'サイドボード' + "\r\n"
          end
        end
      end
    end
  end
  return_text
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
  else
    card_no = data[1].to_i
  end
  data[1] = card_no
  data
end
