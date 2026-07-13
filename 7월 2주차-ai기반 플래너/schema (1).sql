PRAGMA foreign_keys = ON;

CREATE TABLE USER (
  user_id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT,
  birthdate TEXT,
  auth_provider TEXT CHECK(auth_provider IN ('kakao','naver','google','pass','email')),
  auth_provider_id TEXT,
  identity_verified INTEGER DEFAULT 0,
  status TEXT DEFAULT 'active',
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE ADMIN (
  admin_id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT,
  role TEXT,
  invited_by TEXT REFERENCES ADMIN(admin_id),
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE MARKET (
  market_id TEXT PRIMARY KEY,
  market_name TEXT NOT NULL,
  market_type TEXT,
  open_cycle TEXT,
  address_road TEXT,
  address_jibun TEXT,
  lat REAL,
  lon REAL,
  store_count INTEGER,
  item_categories TEXT,
  phone TEXT,
  data_ref_date TEXT,
  managed_by TEXT REFERENCES ADMIN(admin_id)
);

CREATE TABLE MERCHANT (
  merchant_id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  business_number TEXT,
  phone TEXT,
  email TEXT,
  auth_provider TEXT,
  market_id TEXT REFERENCES MARKET(market_id),
  approval_status TEXT DEFAULT 'pending' CHECK(approval_status IN ('pending','approved','rejected')),
  approved_by TEXT REFERENCES ADMIN(admin_id),
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE CONVERSATION (
  conversation_id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES USER(user_id),
  title TEXT,
  is_deleted INTEGER DEFAULT 0,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE MESSAGE (
  message_id TEXT PRIMARY KEY,
  conversation_id TEXT NOT NULL REFERENCES CONVERSATION(conversation_id),
  sender TEXT CHECK(sender IN ('user','ai')),
  content TEXT,
  extracted_slots TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE PLACE (
  place_id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT,
  address TEXT,
  lat REAL,
  lon REAL,
  description TEXT,
  source TEXT
);

CREATE TABLE ITINERARY (
  itinerary_id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES USER(user_id),
  conversation_id TEXT REFERENCES CONVERSATION(conversation_id),
  title TEXT,
  travel_type TEXT,
  start_date TEXT,
  end_date TEXT,
  version INTEGER DEFAULT 1,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE ITINERARY_PLACE (
  itinerary_place_id TEXT PRIMARY KEY,
  itinerary_id TEXT NOT NULL REFERENCES ITINERARY(itinerary_id),
  place_id TEXT REFERENCES PLACE(place_id),
  market_id TEXT REFERENCES MARKET(market_id),
  day_number INTEGER,
  visit_order INTEGER,
  visit_time TEXT
);

CREATE TABLE ITINERARY_HISTORY (
  history_id TEXT PRIMARY KEY,
  itinerary_id TEXT NOT NULL REFERENCES ITINERARY(itinerary_id),
  change_type TEXT CHECK(change_type IN ('추가','삭제','교체','재정렬')),
  snapshot TEXT,
  changed_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE MARKET_STALL (
  stall_id TEXT PRIMARY KEY,
  market_id TEXT NOT NULL REFERENCES MARKET(market_id),
  merchant_id TEXT REFERENCES MERCHANT(merchant_id),
  stall_number TEXT,
  pos_x REAL,
  pos_y REAL,
  stall_type TEXT,
  -- 아래는 공공데이터(상가업소 상권정보) 매칭 원본을 보존하기 위한 컬럼
  -- 상인이 실제 회원가입하면 merchant_id로 연결하고, 이 컬럼들은 참고용으로 남김
  biz_name TEXT,              -- 상호명 (공공데이터 기준)
  category_large TEXT,        -- 업종대분류
  category_mid TEXT,          -- 업종중분류
  category_small TEXT,        -- 업종소분류
  road_address TEXT,          -- 도로명주소
  distance_m REAL,            -- 시장 좌표 기준 매칭 거리(m)
  source_biz_id TEXT,         -- 상가업소번호 (원본 데이터 PK)
  data_source TEXT DEFAULT '소진공_상가업소_202603'
);

CREATE TABLE MARKET_FLOOR_MAP (
  floor_map_id TEXT PRIMARY KEY,
  market_id TEXT NOT NULL REFERENCES MARKET(market_id),
  map_image_url TEXT,
  map_type TEXT,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE QR_CODE (
  qr_id TEXT PRIMARY KEY,
  stall_id TEXT NOT NULL REFERENCES MARKET_STALL(stall_id),
  qr_image_url TEXT,
  issued_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE QR_VISIT_LOG (
  visit_id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES USER(user_id),
  qr_id TEXT NOT NULL REFERENCES QR_CODE(qr_id),
  visited_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE REVIEW (
  review_id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES USER(user_id),
  target_type TEXT CHECK(target_type IN ('place','market','stall')),
  target_id TEXT,
  rating INTEGER CHECK(rating BETWEEN 1 AND 5),
  content TEXT,
  qr_verified INTEGER DEFAULT 0,
  source_visit_id TEXT REFERENCES QR_VISIT_LOG(visit_id),
  is_reported INTEGER DEFAULT 0,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE FAVORITE (
  favorite_id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES USER(user_id),
  target_type TEXT,
  target_id TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE STAMP_TOUR (
  stamp_id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES USER(user_id),
  market_id TEXT NOT NULL REFERENCES MARKET(market_id),
  stamps_collected TEXT,
  completed_at TEXT
);

CREATE TABLE NOTICE (
  notice_id TEXT PRIMARY KEY,
  author_type TEXT CHECK(author_type IN ('merchant','admin')),
  author_id TEXT,
  market_id TEXT REFERENCES MARKET(market_id),
  title TEXT,
  content TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE COUPON (
  coupon_id TEXT PRIMARY KEY,
  issuer_type TEXT CHECK(issuer_type IN ('merchant','admin')),
  issuer_id TEXT,
  stall_id TEXT REFERENCES MARKET_STALL(stall_id),
  market_id TEXT REFERENCES MARKET(market_id),
  discount_info TEXT,
  valid_from TEXT,
  valid_to TEXT
);

CREATE TABLE RESERVATION (
  reservation_id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES USER(user_id),
  stall_id TEXT NOT NULL REFERENCES MARKET_STALL(stall_id),
  item_info TEXT,
  status TEXT DEFAULT '대기' CHECK(status IN ('대기','확인','완료','취소')),
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IMPROVEMENT (
  improvement_id TEXT PRIMARY KEY,
  market_id TEXT NOT NULL REFERENCES MARKET(market_id),
  stall_id TEXT REFERENCES MARKET_STALL(stall_id),
  source_review_id TEXT REFERENCES REVIEW(review_id),
  content TEXT,
  status TEXT DEFAULT '접수' CHECK(status IN ('접수','처리중','완료')),
  handled_by TEXT REFERENCES ADMIN(admin_id),
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE INQUIRY (
  inquiry_id TEXT PRIMARY KEY,
  user_id TEXT REFERENCES USER(user_id),
  category TEXT,
  question TEXT,
  answer TEXT,
  answered_by TEXT REFERENCES ADMIN(admin_id),
  status TEXT DEFAULT '접수' CHECK(status IN ('접수','답변완료')),
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE FEEDBACK (
  feedback_id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES USER(user_id),
  target TEXT,
  content TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_conversation_user ON CONVERSATION(user_id);
CREATE INDEX idx_message_conv ON MESSAGE(conversation_id);
CREATE INDEX idx_itinerary_user ON ITINERARY(user_id);
CREATE INDEX idx_itinerary_place_itinerary ON ITINERARY_PLACE(itinerary_id);
CREATE INDEX idx_stall_market ON MARKET_STALL(market_id);
CREATE INDEX idx_stall_merchant ON MARKET_STALL(merchant_id);
CREATE INDEX idx_qrcode_stall ON QR_CODE(stall_id);
CREATE INDEX idx_qrvisit_user ON QR_VISIT_LOG(user_id);
CREATE INDEX idx_review_user ON REVIEW(user_id);
CREATE INDEX idx_review_target ON REVIEW(target_type, target_id);
CREATE INDEX idx_market_geo ON MARKET(lat, lon);
