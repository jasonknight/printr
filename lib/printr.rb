# coding: utf-8
require 'yaml'
require 'erb'
require 'serialport'
module Printr
  require 'printr/engine' if defined?(Rails)
  mattr_accessor :debug
  @@debug = false
  mattr_accessor :serial_baud_rate
  @@serial_baud_rate = 9600
  mattr_accessor :scope
  @@scope = 'printr'
  mattr_accessor :printr_source #:yaml or :active_record
  @@printr_source = :yaml
  mattr_accessor :logger
  @@logger = STDOUT
  # :active_record => {:class_name => ClassName, :name => :model_field_name, :path => :model_path_name
                       # E.G. printr_model = {:class_name => Printer, :name => :short_name, :path => :location }
                       # to create the list of printers it will call: 
                       # Printer.all.each { |p| @printrs[p.send(Printr.printr_model[:name].snake_case.to_sym)] = p.send(Printr.printr_model[:path]) }
                       # so if you have a printer named bar_printer, then you can print to it with @printr.bar_printer 'textl'
  mattr_accessor :sanitize_tokens #pair list of needle regex, replace must be by 2s, i.e. [/[abc]/,"x",/[123]/,'0']
  @@sanitize_tokens = []
  mattr_accessor :codes
  @@codes = {
      :hr => "=====================\n",
      :header => "\e@\e!\x38",
      :footer => "\n\n\n\n\x1DV\x00\x16\x20105"
    }
  mattr_accessor :printrs
  @@printrs = {}
  mattr_accessor :conf
  @@conf = {}
  def self.new
     return Printr::Machine.new
  end
  def self.log(text)
    if self.logger == STDOUT
      puts text
    else
      @@logger.info text
    end
  end
  def self.setup
    yield self
  end
  def self.get_printers
    if @@printr_source == :yaml then
      @@conf = YAML::load(File.open("#{RAILS_ROOT}/config/printrs.yml")) 
    elsif @@printr_source.class == Hash then
      if @@printr_source[:active_record] then
          @@printr_source[:active_record][:class_name].all.each do |p|
            key = p.send(@@printr_source[:active_record][:name]).to_sym
            @@conf[key] = p.send(@@printr_source[:active_record][:path])
          end
      end
    end
    return self.open_printers
  end
  def self.open_printers
    @@conf.each do |key,value|
      @@printrs[key] = value
     end
    @@printrs
  end 


  # Instance Methods
  class Machine
    def initialize()
      Printr.get_printers
      # You can access these within the views by calling @printr.codes, or whatever
      # you named the instance variable, as it will be snagged by the Binding
      @codes = Printr.codes
      
      # You can override the above codes in the printers.yml, to add
      # say an ASCII header or some nonsense, or if they are using a
      # standard printer etc etc.
      if Printr.conf[:codes] then
        Printr.conf[:codes].each do |key,value|
          Printr.conf[key.to_sym] = value
        end
      end
      Printr.open_printers
    end
    
    def test(key)
      
    end
    
    def logger
      ActiveRecord::Base
	include SalorScope.logger
    end
    def print_to(key,text)
      key = key.to_sym
      if text.nil? then
        Printr.log "[Printr] Umm...text is nil dudes..."
        return
      end
      text = sanitize(text)
      if text.nil? then
        Printr.log "[Printr] Sanitize nillified the text..."
      end
      Printr.log "[Printr] Going ahead with printing of: " + text.to_s[0..100]

      Printr.log "[Printr] Printing to device..." + Printr.conf[key]
      begin
        Printr.log "[Printr] Trying to open #{key} #{Printr.printrs[key]} as a SerialPort."
        SerialPort.open(Printr.printrs[key],9600) do |sp|
          sp.write text
        end
        return
      rescue Exception => e
        Printr.log "[Printr] Failed to open #{key} #{Printr.printrs[key]} as a SerialPort: #{e.inspect}. Trying as a File instead."
      end
      begin
        File.open(Printr.conf[key],'w:ISO8859-15') do |f|
          f.write Printr.codes[:header]
          f.write text
          f.write Printr.codes[:footer]
        end
      rescue Exception => e
        Printr.log "[Printr] Failed to open #{key} #{Printr.printrs[key]} as a File."
      end
    end

    def method_missing(sym, *args, &block)
      Printr.log "[Printr] Called with: #{sym}"
      if Printr.printrs[sym] then
        if args[1].class == Binding then
          print_to(sym,template(args[0],args[1])) #i.e. you call @printr.kitchen('item',binding)
        else
          print_to(sym,args[0])
        end
      end
    end
    def sanitize(text)
      begin
        i = 0
        if Printr.sanitize_tokens.length > 1 then
          begin
            text.gsub!(Printr.sanitize_tokens[i],Printr.sanitize_tokens[i+1])
            i += 2
          end while i < Printr.sanitize_tokens.length
        end
      rescue Exception => e
        Printr.log "[Printr] Error in sanittize"
      end
      return text
    end
    def template(name,bndng)
      Printr.log "[Printr] attempting to print with template #{RAILS_ROOT}/app/views/#{Printr.scope}/#{name}.prnt.erb"
      begin
        erb = ERB.new(File.new("#{RAILS_ROOT}/app/views/#{Printr.scope}/#{name}.prnt.erb",'r').read)
      rescue Exception => e
        Printr.log "[Printr] Exception in view: " + e.inspect
        
      end
      Printr.log "[Printr] returning text"
      text = erb.result(bndng)
      if text.nil? then
        text = 'erb result made me nil'
      end
      return text
    end
  end
end
