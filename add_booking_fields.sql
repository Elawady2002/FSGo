-- إضافة الحقول الجديدة لجدول الحجوزات
-- Add new fields to bookings table

-- إضافة حقل وقت الذهاب
ALTER TABLE bookings 
ADD COLUMN IF NOT EXISTS departure_time TEXT;

-- إضافة حقل وقت العودة
ALTER TABLE bookings 
ADD COLUMN IF NOT EXISTS return_time TEXT;

-- إضافة حقل صورة إثبات الدفع
ALTER TABLE bookings 
ADD COLUMN IF NOT EXISTS payment_proof_image TEXT;

-- إضافة حقل رقم التحويل
ALTER TABLE bookings 
ADD COLUMN IF NOT EXISTS transfer_number TEXT;

-- ✅ تم إضافة الحقول بنجاح!
-- الآن يمكن حفظ تفاصيل الحجز كاملة
