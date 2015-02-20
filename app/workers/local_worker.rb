# encoding: utf-8

module LocalWorker
  def logger
    @logger ||= Logger.new('/dev/null')
  end
end
