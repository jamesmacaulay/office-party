# All the code in this file that has to do with the script/console window is lifted
# directly from the expert-irb.rb sample app that comes with Shoes:
#
# http://github.com/why/shoes/blob/f107ec71ca58ddeaea09d85f1f11197a13f15561/samples/expert-irb.rb

require 'irb/ruby-lex'
require 'stringio'
require 'ftools'


class IO
  def self.latest_output(io)
    io.rewind
    out = io.read
    io.truncate(0)
    io.rewind
    out
  end
end

class MimickIRB < RubyLex
  attr_accessor :started

  class Continue < StandardError; end
  class Empty < StandardError; end

  def initialize
    super
    set_input(StringIO.new)
  end

  def run(str)
    obj = nil
    @io << str
    @io.rewind
    unless l = lex
      raise Empty if @line == ''
    else
      case l.strip
      when "reset"
        @line = ""
      when "time"
        @line = "puts %{You started \#{IRBalike.started.since} ago.}"
      else
        @line << l << "\n"
        if @ltype or @continue or @indent > 0
          raise Continue
        end
      end
    end
    unless @line.empty?
      obj = eval @line, TOPLEVEL_BINDING, "(irb)", @line_no
    end
    @line_no += @line.scan(/\n/).length
    @line = ''
    @exp_line_no = @line_no

    @indent = 0
    @indent_stack = []

    $stdout.rewind
    output = $stdout.read
    $stdout.truncate(0)
    $stdout.rewind
    [output, obj]
  rescue Object => e
    case e when Empty, Continue
    else @line = ""
    end
    raise e
  ensure
    set_input(StringIO.new)
  end

end

CURSOR = ">>"
IRBalike = MimickIRB.new
$stdout = StringIO.new
$stderr = StringIO.new

Shoes.setup do
  gem 'rack >= 0.9.0'
  gem 'sqlite3-ruby'
  unless RUBY_PLATFORM =~ /(win|w)32$/
    gem 'rb-appscript'
  end
  user_dir = (ENV['HOME'] || ENV['USERPROFILE']) + '/.office_party'
  File.makedirs("#{user_dir}/db", "#{user_dir}/log")
  require File.dirname(__FILE__) + '/config/boot'
  Thread.new do
    require 'commands/server'
  end
end

Shoes.app do
  stack do
    @log = para(code(Rails.env + "\n\n"))
  end
  animate(1) do
    [$stdout, $stderr].each_with_index do |io,i|
      out = IO.latest_output(io)
      @log.text = code(@log.text + out) unless out.blank?
    end
  end
  window do
    @str, @cmd = [CURSOR + " "], ""
    stack :width => 1.0, :height => 1.0 do
      background "#555"
      stack :width => 1.0, :height => 50 do
        para "Interactive Ruby ready.", :fill => white, :stroke => red
      end
      @scroll =
        stack :width => 1.0, :height => -50, :scroll => true do
          background "#555"
          @console = para @str, :font => "Monospace 12px", :stroke => "#dfa"
          @console.cursor = -1
        end
    end
    keypress do |k|
      case k
      when "\n"
        begin
          out, obj = IRBalike.run(@cmd)
          @str += ["#@cmd\n",
            span("#{out}=> #{obj.inspect}\n", :stroke => "#fda"),
            "#{CURSOR} "]
          @cmd = ""
        rescue MimickIRB::Empty
        rescue MimickIRB::Continue
          @str += ["#@cmd\n.. "]
          @cmd = ""
        rescue Object => e
          @str += ["#@cmd\n", span("#{e.class}: #{e.message}\n", :stroke => "#fcf"),
            "#{CURSOR} "]
          @cmd = ""
        end
      when String
        @cmd += k
      when :backspace
        @cmd.slice!(-1)
      when :tab
        @cmd += "  "
      when :alt_q
        quit
      when :alt_c
        self.clipboard = @cmd
      when :alt_v
        @cmd += self.clipboard
      end
      @console.replace *(@str + [@cmd])
      @scroll.scroll_top = @scroll.scroll_max
    end
  end
end

