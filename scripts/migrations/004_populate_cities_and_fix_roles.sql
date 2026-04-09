-- ============================================================
-- Migration 004: Populate Cities & Fix Roles
-- Run this in Supabase Dashboard → SQL Editor
-- ============================================================

-- 1. Update user_type check constraint to allow 'coordinator'
ALTER TABLE public.users
DROP CONSTRAINT IF EXISTS users_user_type_check;

ALTER TABLE public.users
ADD CONSTRAINT users_user_type_check
CHECK (user_type IN ('student', 'driver', 'admin', 'station_owner', 'office_owner', 'coordinator'));

-- 2. Enhance cities table structure
ALTER TABLE public.cities
ADD COLUMN IF NOT EXISTS governorate TEXT,
ADD COLUMN IF NOT EXISTS name_en     TEXT,
ADD COLUMN IF NOT EXISTS is_active   BOOLEAN DEFAULT true;

-- 3. Add city_id to users table for linking
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS city_id UUID REFERENCES public.cities(id) ON DELETE SET NULL;

-- 4. Populate Cities and Governorates
-- Clear existing to avoid duplicates if re-running
DELETE FROM public.cities WHERE governorate IS NOT NULL;

INSERT INTO public.cities (name_ar, name_en, governorate) VALUES
-- القاهرة
('القاهرة', 'Cairo', 'القاهرة'),
('القاهرة الجديدة', 'New Cairo', 'القاهرة'),
('مدينة نصر', 'Nasr City', 'القاهرة'),
('المعادي', 'Maadi', 'القاهرة'),
('حلوان', 'Helwan', 'القاهرة'),
('شبرا', 'Shubra', 'القاهرة'),
('الشروق', 'El Shorouk', 'القاهرة'),
('مدينتي', 'Madinaty', 'القاهرة'),
('العاصمة الإدارية', 'New Administrative Capital', 'القاهرة'),

-- الجيزة
('الجيزة', 'Giza', 'الجيزة'),
('6 أكتوبر', '6th of October', 'الجيزة'),
('الشيخ زايد', 'Sheikh Zayed', 'الجيزة'),
('الهرم', 'Al Haram', 'الجيزة'),
('فيصل', 'Faisal', 'الجيزة'),
('المهندسين', 'Mohandessin', 'الجيزة'),
('الدقي', 'Dokki', 'الجيزة'),
('إمبابة', 'Imbaba', 'الجيزة'),
('البدراشين', 'Badrasheen', 'الجيزة'),
('الحوامدية', 'Hawamdia', 'الجيزة'),

-- الإسكندرية
('الإسكندرية', 'Alexandria', 'الإسكندرية'),
('برج العرب', 'Borg El Arab', 'الإسكندرية'),
('العجمي', 'Al Agamy', 'الإسكندرية'),
('سيدي جابر', 'Sidi Gaber', 'الإسكندرية'),
('المنتزه', 'Montaza', 'الإسكندرية'),
('العامرية', 'Amreya', 'الإسكندرية'),

-- الشرقية
('الزقازيق', 'Zagazig', 'الشرقية'),
('العاشر من رمضان', '10th of Ramadan', 'الشرقية'),
('بلبيس', 'Belbeis', 'الشرقية'),
('منيا القمح', 'Minya El Qamh', 'الشرقية'),
('فاقوس', 'Fakous', 'الشرقية'),
('أبو حماد', 'Abu Hammad', 'الشرقية'),
('كفر صقر', 'Kafr Sakr', 'الشرقية'),
('أولاد صقر', 'Awlad Sakr', 'الشرقية'),
('الحسينية', 'Husseiniya', 'الشرقية'),

-- الدقهلية
('المنصورة', 'Mansoura', 'الدقهلية'),
('طلخا', 'Talkha', 'الدقهلية'),
('ميت غمر', 'Mit Ghamr', 'الدقهلية'),
('السنبلاوين', 'Senbellawein', 'الدقهلية'),
('دكرنس', 'Dikirnis', 'الدقهلية'),
('بلقاس', 'Belqas', 'الدقهلية'),
('المنزلة', 'Manzala', 'الدقهلية'),
('شربين', 'Sherbin', 'الدقهلية'),

-- البحيرة
('دمنهور', 'Damanhour', 'البحيرة'),
('كفر الدوار', 'Kafr El Dawar', 'البحيرة'),
('إدكو', 'Edko', 'البحيرة'),
('رشيد', 'Rashid', 'البحيرة'),
('أبو حمص', 'Abu Hummus', 'البحيرة'),
('الدلنجات', 'Delengat', 'البحيرة'),
('كوم حمادة', 'Kom Hamada', 'البحيرة'),
('حوش عيسى', 'Hosh Issa', 'البحيرة'),

-- القليوبية
('بنها', 'Banha', 'القليوبية'),
('شبرا الخيمة', 'Shubra El Kheima', 'القليوبية'),
('قليوب', 'Qalyub', 'القليوبية'),
('القناطر الخيرية', 'El Qanater El Khayreya', 'القليوبية'),
('الخانكة', 'Khanka', 'القليوبية'),
('كفر شكر', 'Kafr Shukr', 'القليوبية'),
('العبور', 'Obour City', 'القليوبية'),
('طوخ', 'Tukh', 'القليوبية'),

-- الغربية
('طنطا', 'Tanta', 'الغربية'),
('المحلة الكبرى', 'El Mahalla El Kubra', 'الغربية'),
('كفر الزيات', 'Kafr El Zayat', 'الغربية'),
('زفتى', 'Zefta', 'الغربية'),
('السنطة', 'Santa', 'الغربية'),
('بسيون', 'Basyoun', 'الغربية'),

-- المنوفية
('شبين الكوم', 'Shibin El Kom', 'المنوفية'),
('قويسنا', 'Quesna', 'المنوفية'),
('بركة السبع', 'Berkat El Sabe', 'المنوفية'),
('تلا', 'Tala', 'المنوفية'),
('منوف', 'Menouf', 'المنوفية'),
('أشمون', 'Ashmoun', 'المنوفية'),
('السادات', 'Sadat City', 'المنوفية'),

-- كفر الشيخ
('كفر الشيخ', 'Kafr El Sheikh', 'كفر الشيخ'),
('دسوق', 'Desouk', 'كفر الشيخ'),
('فوة', 'Fuwa', 'كفر الشيخ'),
('مطوبس', 'Metoubes', 'كفر الشيخ'),
('قلين', 'Qallin', 'كفر الشيخ'),
('الحامول', 'Hamoul', 'كفر الشيخ'),
('بيلا', 'Bila', 'كفر الشيخ'),
('بلطيم', 'Baltim', 'كفر الشيخ'),

-- الفيوم
('الفيوم', 'Fayoum', 'الفيوم'),
('إطسا', 'Itsa', 'الفيوم'),
('طامية', 'Tamia', 'الفيوم'),
('سنورس', 'Sinnuris', 'الفيوم'),
('أبشواي', 'Ibshaway', 'الفيوم'),

-- بني سويف
('بني سويف', 'Beni Suef', 'بني سويف'),
('الواسطى', 'Wasta', 'بني سويف'),
('ناصر', 'Nasser', 'بني سويف'),
('ببا', 'Biba', 'بني سويف'),
('الفشن', 'Fashn', 'بني سويف'),
('سمسطا', 'Somosta', 'بني سويف'),

-- المنيا
('المنيا', 'Minya', 'المنيا'),
('مغاغة', 'Maghagha', 'المنيا'),
('بني مزار', 'Beni Mazar', 'المنيا'),
('مطاي', 'Matay', 'المنيا'),
('سمالوط', 'Samalout', 'المنيا'),
('أبو قرقاص', 'Abu Qurqas', 'المنيا'),
('ملوي', 'Mallawi', 'المنيا'),

-- أسيوط
('أسيوط', 'Assiut', 'أسيوط'),
('ديروط', 'Dayrout', 'أسيوط'),
('القوصية', 'Qusiya', 'أسيوط'),
('أبنوب', 'Abnoub', 'أسيوط'),
('منفلوط', 'Manfalut', 'أسيوط'),
('أبو تيج', 'Abu Tig', 'أسيوط'),
('البداري', 'Badari', 'أسيوط'),

-- سوهاج
('سوهاج', 'Sohag', 'سوهاج'),
('أخميم', 'Akhmim', 'سوهاج'),
('طما', 'Tma', 'سوهاج'),
('طهطا', 'Tahta', 'سوهاج'),
('المراغة', 'Maragha', 'سوهاج'),
('جرجا', 'Girga', 'سوهاج'),
('البلينا', 'Balyana', 'سوهاج'),

-- قنا
('قنا', 'Qena', 'قنا'),
('أبو تشت', 'Abu Tesht', 'قنا'),
('فرشوط', 'Farshout', 'قنا'),
('نجع حمادي', 'Nag Hammadi', 'قنا'),
('دشنا', 'Deshna', 'قنا'),
('قفط', 'Qift', 'قنا'),
('قوص', 'Qus', 'قنا'),

-- الأقصر
('الأقصر', 'Luxor', 'الأقصر'),
('القرنة', 'Qurna', 'الأقصر'),
('البياضية', 'Bayadeya', 'الأقصر'),
('أرمنت', 'Armant', 'الأقصر'),
('إسنا', 'Esna', 'الأقصر'),

-- أسوان
('أسوان', 'Aswan', 'أسوان'),
('دراو', 'Daraw', 'أسوان'),
('كوم أمبو', 'Kom Ombo', 'أسوان'),
('إدفو', 'Edfu', 'أسوان'),

-- دمياط
('دمياط', 'Damietta', 'دمياط'),
('دمياط الجديدة', 'New Damietta', 'دمياط'),
('رأس البر', 'Ras El Bar', 'دمياط'),
('فارسكور', 'Faraskur', 'دمياط'),
('الزرقا', 'Zarqa', 'دمياط'),

-- بورسعيد
('بورسعيد', 'Port Said', 'بورسعيد'),
('بورفؤاد', 'Port Fouad', 'بورسعيد'),

-- الإسماعيلية
('الإسماعيلية', 'Ismailia', 'الإسماعيلية'),
('التل الكبير', 'Tell El Kebir', 'الإسماعيلية'),
('القنطرة', 'Qantara', 'الإسماعيلية'),
('فايد', 'Fayed', 'الإسماعيلية'),

-- السويس
('السويس', 'Suez', 'السويس'),
('حي الأربعين', 'Arbaeen', 'السويس'),
('حي فيصل', 'Faisal District', 'السويس'),

-- البحر الأحمر
('الغردقة', 'Hurghada', 'البحر الأحمر'),
('سفاجا', 'Safaga', 'البحر الأحمر'),
('القصير', 'Quseir', 'البحر الأحمر'),
('رأس غارب', 'Ras Gharib', 'البحر الأحمر'),
('مرسى علم', 'Marsa Alam', 'البحر الأحمر'),

-- الوادي الجديد
('الخارجة', 'Kharga', 'الوادي الجديد'),
('الداخلة', 'Dakhla', 'الوادي الجديد'),
('الفرافرة', 'Farafra', 'الوادي الجديد'),

-- مطروح
('مرسى مطروح', 'Marsa Matrouh', 'مطروح'),
('الحمام', 'Hamam', 'مطروح'),
('العلمين', 'El Alamein', 'مطروح'),
('الضبعة', 'Dabaa', 'مطروح'),
('سيوة', 'Siwa', 'مطروح'),

-- شمال سيناء
('العريش', 'Arish', 'شمال سيناء'),
('بئر العبد', 'Bir El Abd', 'شمال سيناء'),
('الشيخ زويد', 'Sheikh Zuweid', 'شمال سيناء'),
('رفح', 'Rafah', 'شمال سيناء'),

-- جنوب سيناء
('الطور', 'El Tor', 'جنوب سيناء'),
('شرم الشيخ', 'Sharm El Sheikh', 'جنوب سيناء'),
('دهب', 'Dahab', 'جنوب سيناء'),
('نويبع', 'Nuweiba', 'جنوب سيناء'),
('طابا', 'Taba', 'جنوب سيناء');
