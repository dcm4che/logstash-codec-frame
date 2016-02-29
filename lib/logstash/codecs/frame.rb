# encoding: utf-8
require "logstash/codecs/base"
require "logstash/util/charset"

# Frame-oriented text data.
#
# Decoding behavior: Only whole frame events will be emitted.
#
# Encoding behavior: Each event will be emitted with a prefixed <length><delimiter>.
class LogStash::Codecs::Frame < LogStash::Codecs::Base
  config_name "frame"

  # Set the desired text format for encoding.
  config :format, :validate => :string

  # This only affects "plain" format logs since json is `UTF-8` already.
  config :charset, :validate => ::Encoding.name_list, :default => "UTF-8"

  # Change the delimiter that separates frame length from the data
  config :delimiter, :validate => :string, :default => " "

  public
  def register
    @buffer = ""
    @offset
    @frame_length
    @converter = LogStash::Util::Charset.new(@charset)
    @converter.logger = @logger
  end

  public
  def decode(data)
    @buffer += data
    while (nextMessage)
      yield LogStash::Event.new("message" => @converter.convert(@buffer[@offset, @frameLength]))
      @buffer.slice!(0, @offset + @frameLength)
      @offset = nil
    end
  end # def decode

  public
  def encode(event)
    if event.is_a? LogStash::Event and @format
      @on_event.call(event, encodeFrameLength(event.sprintf(@format)))
    else
      @on_event.call(event, encodeFrameLength(event.to_s))
    end
  end # def encode

  private
  def nextMessage()
    if (@offset.nil?)
      @offset = @buffer.index(@delimiter);
      if (@offset.nil?)
        return false
      end
      @frameLength = @buffer[0, @offset].to_i
      @offset +=  @delimiter.length
    end
    return @buffer.length >= @offset + @frameLength
  end # def nextMessage

  private
  def encodeFrameLength(message)
    return message.length.to_s + @delimiter + message
  end # def encodeFrameLength

end # class LogStash::Codecs::Frame
