const nodemailer = require('nodemailer');

/**
 * Gửi email chứa mã OTP khôi phục mật khẩu
 * @param {string} toEmail - Địa chỉ email người nhận
 * @param {string} otp - Mã OTP gồm 6 chữ số
 * @returns {Promise<boolean>}
 */
const sendOtpEmail = async (toEmail, otp) => {
  const emailUser = process.env.EMAIL_USER;
  const emailPass = process.env.EMAIL_PASS;

  // Nếu người dùng chưa cấu hình EMAIL_USER và EMAIL_PASS trong .env
  if (!emailUser || !emailPass || emailUser.trim() === '' || emailPass.trim() === '') {
    console.log('\n======================================================');
    console.log('🔔 [DEV MODE - CHƯA CẤU HÌNH GMAIL TRONG .ENV]');
    console.log(`📧 Gửi mã OTP tới: ${toEmail}`);
    console.log(`🔑 MÃ OTP CỦA BẠN LÀ: [ ${otp} ] (Hiệu lực trong 5 phút)`);
    console.log('👉 Vui lòng điền EMAIL_USER và EMAIL_PASS vào .env để gửi mail thực tế.');
    console.log('======================================================\n');
    return true;
  }

  try {
    const transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: emailUser,
        pass: emailPass,
      },
    });

    const mailOptions = {
      from: `"HomeFix Support" <${emailUser}>`,
      to: toEmail,
      subject: `[HomeFix] Mã xác nhận đặt lại mật khẩu: ${otp}`,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 560px; margin: 0 auto; padding: 24px; border: 1px solid #e2e8f0; border-radius: 12px; background-color: #ffffff;">
          <div style="text-align: center; margin-bottom: 24px;">
            <h1 style="color: #1976D2; margin: 0; font-size: 26px; font-weight: bold;">🏠 HomeFix</h1>
            <p style="color: #64748b; font-size: 14px; margin-top: 4px;">Dịch vụ sửa chữa tại nhà tiện lợi & tin cậy</p>
          </div>

          <div style="border-top: 1px solid #e2e8f0; padding-top: 20px;">
            <p style="font-size: 15px; color: #334155; line-height: 1.6;">Xin chào bạn,</p>
            <p style="font-size: 15px; color: #334155; line-height: 1.6;">
              Chúng tôi nhận được yêu cầu đặt lại mật khẩu cho tài khoản liên kết với địa chỉ email: <strong>${toEmail}</strong>.
            </p>
            <p style="font-size: 15px; color: #334155; line-height: 1.6;">
              Mã xác minh OTP của bạn là:
            </p>

            <div style="text-align: center; margin: 28px 0;">
              <div style="display: inline-block; background-color: #f0f7ff; border: 2px dashed #1976D2; border-radius: 8px; padding: 14px 32px; letter-spacing: 8px; font-size: 32px; font-weight: bold; color: #1976D2;">
                ${otp}
              </div>
              <p style="color: #e11d48; font-size: 13px; margin-top: 10px; font-weight: 500;">
                ⏱ Mã xác nhận có hiệu lực trong vòng 5 phút.
              </p>
            </div>

            <div style="background-color: #fffbeb; border-left: 4px solid #f59e0b; padding: 12px 16px; border-radius: 4px; margin-bottom: 20px;">
              <p style="font-size: 13px; color: #b45309; margin: 0; line-height: 1.5;">
                ⚠️ <strong>Cảnh báo bảo mật:</strong> Tuyệt đối không chia sẻ mã này cho bất kỳ ai, kể cả nhân viên HomeFix. Nếu bạn không yêu cầu đặt lại mật khẩu, vui lòng bỏ qua email này.
              </p>
            </div>

            <p style="font-size: 14px; color: #64748b; line-height: 1.5; margin-top: 24px;">
              Trân trọng,<br>
              <strong>Đội ngũ vận hành HomeFix</strong>
            </p>
          </div>
        </div>
      `,
    };

    await transporter.sendMail(mailOptions);
    return true;
  } catch (error) {
    console.error('❌ Lỗi khi gửi email OTP qua Gmail:', error.message);
    throw new Error('Không thể gửi email xác thực. Vui lòng kiểm tra lại cấu hình EMAIL_USER và EMAIL_PASS.');
  }
};

module.exports = {
  sendOtpEmail,
};
