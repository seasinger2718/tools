class CSVReader

  def initialize(options = {})
    @field_separator = options[:field_separator] || ','
    @field_quotes = options[:field_quotes] || '"'
    @header_lines = options[:header_lines] || 1
    @field_quotes_regex_start = Regexp.new(%{^[#{@field_quotes}]})
    @field_quotes_regex_end = Regexp.new(%{[#{@field_quotes}]$})
  end
  
  def read(file_name)
    total_lines_read = 0
    file_options = {
      mode: "r:bom|utf-8"
    }
    File.open(file_name,file_options) do |file|
      while raw_line = file.gets
        total_lines_read += 1
        next if total_lines_read <= @header_lines
        line = raw_line.strip.chomp
        if block_given?
          yield parse_line(line)
        end
      end
    end
  end

  def parse_line(line)
    fields = []
    pending_quote = false
    raw_field = ''
    line.each_char do |c|
      #puts "c #{c}"
      if c == @field_quotes
         pending_quote = ! pending_quote
         #puts "c is a quote and #{pending_quote ? 'is' : 'is not'} pending"
         next
      end
      if (c == @field_separator) and (not pending_quote)
        #puts "c is a separator and no quote pending"
        fields << raw_field.strip.chomp
        #puts %{Field "#{raw_field.strip.chomp}"}
        raw_field = ''
        next
      end
      raw_field << c
    end
    # Catch last field
    if raw_field != ''
      fields << raw_field.strip.chomp
    end
    
    return fields
  end
  
  class << self
    
    def foreach(file_name,options = {},&block)
      csv_reader = CSVReader.new(options)
      return csv_reader.read(file_name,&block)
    end
    
  end
  
end
