# coding: utf-8

require "spec_helper"

module Modou
  describe Ticket do
    it { should respond_to :user_name }
    it { should respond_to :user_email }
    it { should respond_to :user_phone }
    it { should respond_to :order_number }
    it { should respond_to :support_type }
    it { should respond_to :additional_info }

    it { should respond_to :to_human_readable_text }

    it { should respond_to :support_type_in_chinese }

    let(:params) {
      {
        name: 'hello',
        email: 'i@fye.im',
        phone: '13800138000',
        order_number: '123456789012',
        reason: 'refund-not-received',
        comment: 'it sucks'
      }
    }

    describe 'class methods' do
      subject { Ticket }
      it { should respond_to :create_from_params }

      describe '.create_from_params' do

        it 'creates from params' do
          ticket = subject.create_from_params(params)
          ticket.user_name.should == 'hello'
          ticket.user_email.should == 'i@fye.im'
          ticket.user_phone.should == '13800138000'
          ticket.order_number.should == '123456789012'
          ticket.support_type.should == 'refund-not-received'
          ticket.additional_info.should == 'it sucks'
        end
      end

      it { should respond_to :support_type_in_chinese }

      # <option value="refund-not-received">我要退款(未收到货)</option>
      # <option value="refund-received">我要退货(已收到货)</option>
      # <option value="replace">我要换货</option>
      # <option value="repair">我要维修</option>
      # <option value="other">其他</option>

      describe '.support_type_in_chinese' do
        it 'translates' do
          subject.support_type_in_chinese('refund-not-received').should == '我要退款(未收到货)'
          subject.support_type_in_chinese('refund-received').should == '我要退货(已收到货)'
          subject.support_type_in_chinese('replace').should == '我要换货'
          subject.support_type_in_chinese('repair').should == '我要维修'
          subject.support_type_in_chinese('other').should == '其他'

          expect { subject.support_type_in_chinese('random')}.to raise_exception("illegal support_type: 'random'")
        end
      end
    end

    describe '#to_human_readable_text' do
      let(:ticket) { Ticket.create_from_params(params) }
      subject { ticket }

      it 'generates pretty human readable text' do
        expected = %q{
          姓名: hello
          邮箱地址: i@fye.im
          电话号码: 13800138000
          订单号: 123456789012
          售后服务类型: 我要退款(未收到货)
          备注: it sucks
        }.gsub(/^\s+/, '')

        subject.to_human_readable_text.should == expected
      end
    end
  end
end
