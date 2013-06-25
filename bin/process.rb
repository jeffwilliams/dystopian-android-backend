#!/usr/bin/env ruby
require 'nokogiri'
require 'digest'
require 'lib/cards_processor'

CardsProcessor.new("test/data").process "test/data/cards1.xml", "/tmp/output.xml"

