# encoding: utf-8
require_relative '../spec_helper'
require "logstash/codecs/frame"
require "logstash/event"

describe LogStash::Codecs::Frame do
  subject do
    next LogStash::Codecs::Frame.new
  end

  context "#encode" do
    let (:event) {LogStash::Event.new({"message" => "hello world", "host" => "test"})}

    it "should prefix message with length" do
      subject.format = "%{message}"
      expect(subject).to receive(:on_event).once.and_call_original
      subject.on_event do |e, d|
        insist {d} == "11 hello world"
      end
      subject.encode(event)
    end

  end

  context "#decode" do
    it "should return an event from an ascii string" do
      decoded = false
      subject.decode("11 hello world") do |e|
        decoded = true
        insist { e.is_a?(LogStash::Event) }
        insist { e["message"] } == "hello world"
      end
      insist { decoded } == true
    end

    it "should return an event from a valid utf-8 string" do
      subject.decode("7 München") do |e|
        insist { e.is_a?(LogStash::Event) }
        insist { e["message"] } == "München"
      end
    end

    it "should return 1 event from 2 strings" do
      messages = []
      subject.decode("11 hello") do |e|
        messages << e["message"]
      end
      subject.decode(" world") do |e|
        messages << e["message"]
      end
      insist { messages } == ["hello world" ]
    end

    it "should return 2 events from 3 strings" do
      messages = []
      subject.decode("11 hello") do |e|
        messages << e["message"]
      end
      subject.decode(" world7") do |e|
        messages << e["message"]
      end
      subject.decode(" München") do |e|
        messages << e["message"]
      end
      insist { messages } == ["hello world", "München"]
    end

    it "should return 2 events from one string" do
      messages = []
      subject.decode("11 hello world7 München") do |e|
        messages << e["message"]
      end
      insist { messages } == ["hello world", "München"]
    end

  end

end
