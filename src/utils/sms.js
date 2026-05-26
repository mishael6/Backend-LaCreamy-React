import axios from 'axios';

/**
 * Send SMS via Payloqa
 * Docs: https://payloqa.com/docs
 */
export const sendSMS = async (phone, message) => {
  try {
    const response = await axios.post(
      'https://api.payloqa.com/v1/sms/send',
      {
        to: phone,
        from: process.env.PAYLOQA_SENDER_ID || 'LaCreamy',
        message,
      },
      {
        headers: {
          Authorization: `Bearer ${process.env.PAYLOQA_API_KEY}`,
          'Content-Type': 'application/json',
        },
      }
    );

    return { success: true, data: response.data };
  } catch (error) {
    console.error('âŒ Payloqa SMS Error:', error.response?.data || error.message);
    return { success: false, error: error.response?.data || error.message };
  }
};

/**
 * Generate a 6-digit OTP
 */
export const generateOTP = () => {
  return Math.floor(1000 + Math.random() * 9000).toString();
};

/**
 * Format phone number to international format
 * Converts 0241234567 â†’ 233241234567
 */
export const formatPhone = (phone) => {
  const cleaned = phone.replace(/\D/g, '');
  if (cleaned.startsWith('0')) {
    return '233' + cleaned.slice(1);
  }
  if (cleaned.startsWith('233')) {
    return cleaned;
  }
  return cleaned;
};

