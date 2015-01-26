json.array!(@jobs) do |job|
  json.extract! job, :id
  json.url job_url(job, format: :json)
end
