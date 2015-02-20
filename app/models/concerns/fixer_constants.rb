# encoding: utf-8

module FixerConstants
  CREATED     = 'created'     # When task first created
  PROCESSING  = 'processing'  # When task first picked up by a processor
  COMPLETE    = 'complete'    # task has completed succcessfully
  ERROR       = 'error'       # task failed for some reason, but could be retried.
  RETRYING    = 'retrying'    # After an error, when the task has been sent to a queue to try again (like created)
  CANCELLED   = 'cancelled'   # Manually cancelled, no more retries, or callbacks

  PROGRESS    = 'progress'    # update with the current % of progress for the task, does not change task state
  INFO        = 'info'        # info logging does not change status of the task

  STATUS_VALUES = [CREATED, PROCESSING, COMPLETE, ERROR, RETRYING, CANCELLED].freeze
  LOG_STATUS_VALUES = (STATUS_VALUES + [PROGRESS, INFO]).freeze

  DEFAULT_PRIORITY = 3
  MAX_PRIORITY = 4

  JOB_TYPES = ['audio', 'image', 'file', 'text', 'test']
end
