require "spec_helper"

describe Ticket do
  it { should respond_to :username }
  it { should respond_to :source_ip }
end
