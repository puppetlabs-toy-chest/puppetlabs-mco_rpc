#!/opt/puppetlabs/puppet/bin/ruby

require 'json'
require 'mcollective'
require 'mcollective/application/rpc'

class MCollective::Connector::NullConn
  def error
    raise NotImplementedError, 'Connection is not available when running agent as a task'
  end

  def connect
    error
  end

  def disconnect
    error
  end

  def publish(_msg)
    error
  end

  def recieve
    error
  end

  def subscribe(_agent, _type, _collective)
    error
  end

  def unsubscribe(_agent, _type, _collective)
    error
  end
end

class MCollective::PuppetTask
  attr_accessor :params, :conn, :configloaded

  class TaskError < RuntimeError
    attr_accessor :result
    def initialize(kind, msg, details = nil)
      @message = msg
      @result = {
        kind: kind,
        msg: msg,
        details: details || {},
      }
    end
  end

  def initialize(params)
    @params = params
    @conn = MCollective::Connector::NullConn.new
    @configloaded = false
  end

  def loadconfig
    unless @configloaded
      if MCollective::Util.windows?
        configfile = File.join(MCollective::Util.windows_prefix, 'etc', 'server.cfg')
      else
        # search for the server.cfg in the AIO path then the traditional one
        configfiles = ['/etc/puppetlabs/mcollective/server.cfg',
                       '/etc/mcollective/server.cfg']

        found = configfiles.find_index { |file| File.readable?(file) }

        # didn't find any? default to the first
        if found.nil?
          found = 0
        end

        configfile = configfiles[found]
      end
      config = MCollective::Config.instance
      config.loadconfig(configfile)
      @configloaded = true
    end
  end

  def agents
    @agents ||= begin
      agents = MCollective::PluginManager.find_and_load('agent')
      agents.each_with_object({}) do |agent, m|
        cls = Kernel.const_get(agent)
        if cls.ancestors.include?(MCollective::RPC::Agent) && cls.activate?
          inst = cls.new
          m[inst.ddl.meta[:name]] = inst
        end
      end
    end
  end

  def process_result(result)
    if result[:statuscode] == 0
      result[:data]
    else
      raise TaskError.new('puppetlabs.mco_rpc/mco_error',
                          result[:statusmsg],
                          statuscode: result[:statuscode],
                          data: result[:data])
    end
  end

  def get_agent
    agent = agents[@params[:agent]]
    if agent.nil?
      raise TaskError.new('puppetlabs.mco_rpc/unknown-agent',
                          "'#{@params[:agent]}' is not available.",
                          agent: @params[:agent])
    end
    agent
  end

  def mco_message
    { body: {
      action: @params[:action],
      data: @params[:data] || {},
    } }
  end

  def init_data
    if  @params[:arguments]
      if @params[:data] && !@params[:data].empty?
        raise TaskError.new('puppetlabs.mco_rpc/invalid_args',
                            "Cannot pass both arguments and data '#{arg}'")
      end
      @params[:data] = {}
      @params[:arguments].split.each do |arg|
        # This is the regex MCO uses.
        if arg =~ /^(.+?)=(.+)$/
          @params[:data][$1.to_sym] = $2
        else
          raise TaskError.new('puppetlabs.mco_rpc/invalid_args',
                              "Cannot parse argument '#{arg}'")
        end
      end
      ddl = get_agent.ddl ? get_agent.ddl.entities[@params[:action]] : {}
      MCollective::Application::Rpc.new.string_to_ddl_type(@params[:data], ddl)
    else
      @params[:data] ||= {}
    end
  end

  def run_action
    result = get_agent.handlemsg(mco_message, @conn)
    if result.nil?
      { _output: 'Agent did not produce a result.' }
    else
      process_result(result)
    end
  rescue TaskError => e
    { _error: e.result }
  rescue Exception => e
    { _error: {
      kind: 'puppetlabs.mco_rpc/unknown_error',
      msg: e.message,
      details: {},
    } }
  end
end

if $PROGRAM_NAME == __FILE__
  params = JSON.parse(STDIN.read, symbolize_names: true)
  runner = MCollective::PuppetTask.new(params)
  runner.loadconfig
  runner.init_data
  result = runner.run_action
  puts result.to_json
end
