# coding: utf-8

module Modou
  class Ticket
    attr_accessor :user_name, :user_phone, :user_email, :order_number, :support_type, :additional_info

    def initialize(params = {})
      @user_name = params[:name]
      @user_phone = params[:phone]
      @user_email = params[:email]
      @order_number = params[:order_number]
      @support_type = params[:reason]
      @additional_info = params[:comment]
    end

    def support_type_in_chinese
      self.class.support_type_in_chinese(@support_type)
    end

    def to_human_readable_text
      %{
        姓名: #{@user_name}
        邮箱地址: #{@user_email}
        电话号码: #{@user_phone}
        订单号: #{@order_number}
        售后服务类型: #{support_type_in_chinese}
        备注: #{@additional_info}

        -----------------
        以上信息由 http://support.ly.md 自动生成
      }.gsub(/^\s+/, '')
    end

    class << self
      def create_from_params(params)
        new(params)
      end

      # <option value="refund-not-received">我要退款(未收到货)</option>
      # <option value="refund-received">我要退货(已收到货)</option>
      # <option value="replace">我要换货</option>
      # <option value="repair">我要维修</option>
      # <option value="other">其他</option>

      def support_type_in_chinese(support_type)
        case support_type
        when 'refund-not-received'
          '我要退款(未收到货)'
        when 'refund-received'
          '我要退货(已收到货)'
        when 'replace'
          '我要换货'
        when 'repair'
          '我要维修'
        when 'other'
          '其他'
        else
          raise "illegal support_type: '#{support_type}'"
        end
      end
    end
  end
end
