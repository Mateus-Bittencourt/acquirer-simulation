require 'csv'
require 'net/http'
require 'uri'
require 'json'

class CsvProcessorController < ApplicationController
  def upload
    file = params[:file]
    return render json: { error: 'No file provided' }, status: :unprocessable_entity unless file

    # Verificar se o arquivo possui o formato correto
    required_headers = %w[transaction_id merchant_id user_id card_number transaction_date transaction_amount device_id has_cbk]
    csv_headers = CSV.read(file.path, headers: true).headers

    missing_headers = required_headers - csv_headers
    if missing_headers.any?
      return render json: { error: "Missing headers: #{missing_headers.join(', ')}" }, status: :unprocessable_entity
    end

    ActiveRecord::Base.transaction do
      CSV.foreach(file.path, headers: true) do |row|
        transaction = Transaction.new(
          transaction_id: row['transaction_id'],
          merchant_id: row['merchant_id'],
          user_id: row['user_id'],
          card_number: row['card_number'],
          transaction_date: row['transaction_date'],
          transaction_amount: row['transaction_amount'],
          device_id: row['device_id'],
          has_cbk: row['has_cbk'] == 'TRUE'
        )

        if transaction.save
          send_to_anti_fraud_api(transaction)
        else
          Rails.logger.error("Failed to save transaction: #{transaction.errors.full_messages.join(', ')}")
          raise ActiveRecord::Rollback
        end
      end
    end

    render json: { message: 'File processed successfully' }, status: :ok
  end

  private

  def send_to_anti_fraud_api(transaction)
    uri = URI.parse('http://localhost:3001/transactions')
    request = Net::HTTP::Post.new(uri)
    request.content_type = 'application/json'
    request.body = {
      transaction_id: transaction.transaction_id,
      merchant_id: transaction.merchant_id,
      user_id: transaction.user_id,
      card_number: transaction.card_number,
      transaction_date: transaction.transaction_date,
      transaction_amount: transaction.transaction_amount,
      device_id: transaction.device_id,
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.request(request)
    end

    if response.is_a?(Net::HTTPSuccess)
      response_body = JSON.parse(response.body)
      recommendation = response_body['recommendation']
      transaction.update!(recommendation: recommendation)
    else
      Rails.logger.error("Failed to send transaction #{transaction.transaction_id} to antifraud API: #{response.body}")
    end
  end
end
