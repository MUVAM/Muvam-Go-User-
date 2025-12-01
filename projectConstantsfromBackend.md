# Project Constants Reference
## Complete list of all constants used in the SUPER-APP Taxi Application
---
## Table of Contents1. [User & Role Constants](#user--role-constants)2. [Ride & Service Type Constants](#ride--service-type-constants)3. [Payment Constants](#payment-constants)4. [Wallet & Transaction Constants](#wallet--transaction-constants)5. [Report & Safety Constants](#report--safety-constants)6. [Call & WebRTC Constants](#call--webrtc-constants)7. [WebSocket Message Constants](#websocket-message-constants)8. [Admin & Role Constants](#admin--role-constants)9. [Promotion & Promo Code Constants](#promotion--promo-code-constants)10. [Earnings & Payout Constants](#earnings--payout-constants)11. [Rating Constants](#rating-constants)12. [System Configuration Constants](#system-configuration-constants)13. [API Version Constants](#api-version-constants)
---
## User & Role Constants
**File**: [internal/models/user.go](internal/models/user.go)
```gotype Role string
const (    RolePassenger Role = "passenger" // Regular passenger user    RoleDriver Role = "driver" // Driver user)```
**Usage**: User role designation**Values**: `passenger`, `driver`
---
## Ride & Service Type Constants
**File**: [internal/models/ride.go](internal/models/ride.go)
### Service Types```gotype ServiceType string
const (    ServiceTaxi ServiceType = "taxi" // Taxi/ride-hailing service    ServiceDelivery ServiceType = "delivery" // Delivery service)```
### Vehicle Types```gotype VehicleType string
const (    // Taxi vehicles    VehicleRegular VehicleType = "regular" // Standard/economy taxi    VehicleFancy VehicleType = "fancy" // Premium/comfort taxi    VehicleVIP VehicleType = "vip" // Luxury/executive taxi
    // Delivery vehicles    VehicleBicycle VehicleType = "bicycle" // Bicycle delivery    VehicleVehicle VehicleType = "vehicle" // Car/van delivery    VehicleMotorbike VehicleType = "motorbike" // Motorcycle delivery)```
### Payment Methods (for rides)```gotype RidePaymentMethod string
const (    PaymentGateway RidePaymentMethod = "gateway" // Online payment gateway    PaymentWallet RidePaymentMethod = "wallet" // Wallet payment    PaymentInCar RidePaymentMethod = "in_car" // Cash payment in vehicle)```
### Ride Status```gotype RideStatus string
const (    StatusRequested RideStatus = "requested" // Ride requested, looking for driver    StatusAccepted RideStatus = "accepted" // Driver accepted the ride    StatusArrived RideStatus = "arrived" // Driver arrived at pickup    StatusStarted RideStatus = "started" // Ride in progress    StatusCompleted RideStatus = "completed" // Ride completed successfully    StatusCancelled RideStatus = "cancelled" // Ride cancelled)```
---
## Payment Constants
**File**: [internal/models/payment.go](internal/models/payment.go)
### Payment Method Types```gotype PaymentMethodType string
const (    PaymentMethodTransferCard PaymentMethodType = "transfer-card" // Paystack card payment    PaymentMethodInCar PaymentMethodType = "in_car" // Cash payment    PaymentMethodWallet PaymentMethodType = "wallet" // Wallet payment    PaymentMethodPay4Me PaymentMethodType = "pay4me" // Pay4Me payment    PaymentMethodPromo PaymentMethodType = "promo" // Promo code payment)```
### Payment Status```gotype PaymentStatus string
const (    PaymentStatusPending PaymentStatus = "pending" // Payment initiated    PaymentStatusSuccess PaymentStatus = "success" // Payment successful    PaymentStatusFailed PaymentStatus = "failed" // Payment failed    PaymentStatusAbandoned PaymentStatus = "abandoned" // Payment abandoned)```
---
## Wallet & Transaction Constants
**File**: [internal/models/wallet.go](internal/models/wallet.go)
### Wallet Types```gotype WalletType string
const (    WalletTypeDriver WalletType = "driver" // Driver wallet    WalletTypePassenger WalletType = "passenger" // Passenger wallet)```
### Transaction Types```gotype TransactionType string
const (    TransactionTypeCredit TransactionType = "credit" // Money added to wallet    TransactionTypeDebit TransactionType = "debit" // Money removed    TransactionTypeRideCharge TransactionType = "ride_charge" // Deducted for ride    TransactionTypeRideEarning TransactionType = "ride_earning" // Added from ride    TransactionTypeDeposit TransactionType = "deposit" // Manual deposit    TransactionTypeWithdrawal TransactionType = "withdrawal" // Manual withdrawal    TransactionTypeRefund TransactionType = "refund" // Refund from cancelled ride    TransactionTypeCommission TransactionType = "commission" // Platform commission    TransactionTypeTip TransactionType = "tip" // Tip to driver    TransactionTypeBonus TransactionType = "bonus" // Bonus/promotion)```
### Transaction Status```gotype TransactionStatus string
const (    TransactionPending TransactionStatus = "pending" // Transaction pending    TransactionCompleted TransactionStatus = "completed" // Transaction completed    TransactionFailed TransactionStatus = "failed" // Transaction failed    TransactionReversed TransactionStatus = "reversed" // Transaction reversed)```
---
## Report & Safety Constants
**File**: [internal/models/report.go](internal/models/report.go)
### Report Categories```gotype ReportCategory string
const (    // Driver-related issues    ReportRecklessDriving ReportCategory = "reckless_driving"    ReportUnprofessional ReportCategory = "unprofessional_behavior"    ReportWrongRoute ReportCategory = "wrong_route"    ReportUnsafeVehicle ReportCategory = "unsafe_vehicle"    ReportDriverNoShow ReportCategory = "driver_no_show"
    // Passenger-related issues    ReportPassengerNoShow ReportCategory = "passenger_no_show"    ReportRudeBehavior ReportCategory = "rude_behavior"    ReportRefusedToPay ReportCategory = "refused_to_pay"    ReportDamageToVehicle ReportCategory = "damage_to_vehicle"    ReportInappropriate ReportCategory = "inappropriate_behavior"
    // General issues    ReportHarassment ReportCategory = "harassment"    ReportSafetyConcern ReportCategory = "safety_concern"    ReportFraud ReportCategory = "fraud"    ReportOther ReportCategory = "other")```
### Report Status```gotype ReportStatus string
const (    ReportStatusPending ReportStatus = "pending" // Just submitted    ReportStatusReviewing ReportStatus = "reviewing" // Under investigation    ReportStatusResolved ReportStatus = "resolved" // Issue resolved    ReportStatusRejected ReportStatus = "rejected" // Invalid report)```
### Report Severity```gotype ReportSeverity string
const (    SeverityLow ReportSeverity = "low" // Minor issue    SeverityMedium ReportSeverity = "medium" // Moderate issue    SeverityHigh ReportSeverity = "high" // Serious issue    SeverityCritical ReportSeverity = "critical" // Critical safety issue)```
---
## Call & WebRTC Constants
**File**: [internal/models/call.go](internal/models/call.go)
### Call Status```gotype CallStatus string
const (    CallStatusInitiated CallStatus = "initiated" // Call initiated    CallStatusRinging CallStatus = "ringing" // Ringing    CallStatusActive CallStatus = "active" // Call in progress    CallStatusCompleted CallStatus = "completed" // Call ended normally    CallStatusRejected CallStatus = "rejected" // Call rejected    CallStatusMissed CallStatus = "missed" // Call not answered    CallStatusFailed CallStatus = "failed" // Call failed)```
---
## WebSocket Message Constants
**File**: [internal/websocket/hub.go](internal/websocket/hub.go)
### Message Types```gotype MessageType string
const (    // Ride-related messages    MessageTypeRideRequest MessageType = "ride_request"    MessageTypeRideAccepted MessageType = "ride_accepted"    MessageTypeRideArrived MessageType = "ride_arrived"    MessageTypeRideStarted MessageType = "ride_started"    MessageTypeRideCompleted MessageType = "ride_completed"
    // Communication messages    MessageTypeChat MessageType = "chat"    MessageTypeDriverLocation MessageType = "driver_location"    MessageTypeLocationUpdate MessageType = "location_update"
    // Connection messages    MessageTypePing MessageType = "ping"    MessageTypePong MessageType = "pong"
    // WebRTC Call signaling messages    MessageTypeCallInitiate MessageType = "call_initiate"    MessageTypeCallRinging MessageType = "call_ringing"    MessageTypeCallAnswer MessageType = "call_answer"    MessageTypeCallReject MessageType = "call_reject"    MessageTypeCallEnd MessageType = "call_end"    MessageTypeCallOffer MessageType = "call_offer"    MessageTypeCallAnswerSDP MessageType = "call_answer_sdp"    MessageTypeCallIceCandidate MessageType = "call_ice_candidate")```
### WebSocket Client Constants**File**: [internal/websocket/client.go](internal/websocket/client.go)
```goconst (    writeWait = 10 * time.Second // Time to write message    pongWait = 60 * time.Second // Time to read pong    pingPeriod = (pongWait * 9) / 10 // Ping period (54 seconds)    maxMessageSize = 65536 // 64KB max message size)```
---
## Admin & Role Constants
**File**: [internal/models/admin.go](internal/models/admin.go)
### Admin Roles```gotype AdminRole string
const (    RoleSuperAdmin AdminRole = "super_admin" // Full system access    RoleDispatcher AdminRole = "dispatcher" // Live dispatch & monitoring    RoleSupport AdminRole = "support" // Customer support)```
---
## Promotion & Promo Code Constants
**File**: [internal/models/promotion.go](internal/models/promotion.go)
### Promo Types```gotype PromoType string
const (    PromoTypeFixed PromoType = "fixed" // Fixed amount discount    PromoTypePercentage PromoType = "percentage" // Percentage discount)```
### Promo Status```gotype PromoStatus string
const (    PromoStatusActive PromoStatus = "active" // Promo active    PromoStatusExpired PromoStatus = "expired" // Promo expired)```
---
## Earnings & Payout Constants
**File**: [internal/models/earnings.go](internal/models/earnings.go)
### Payment Types (for earnings)```gotype PaymentType string
const (    PaymentTypeCash PaymentType = "cash" // Cash payment    PaymentTypeCard PaymentType = "card" // Card payment)```
### Payout Status```gotype PayoutStatus string
const (    PayoutPending PayoutStatus = "pending" // Payout pending    PayoutProcessing PayoutStatus = "processing" // Being processed    PayoutCompleted PayoutStatus = "completed" // Payout completed    PayoutFailed PayoutStatus = "failed" // Payout failed    PayoutCancelled PayoutStatus = "cancelled" // Payout cancelled)```
### Earnings Service Constants**File**: [internal/services/earnings_service.go](internal/services/earnings_service.go)
```goconst (    DefaultCommissionRate = 0.20 // 20% platform commission)```
---
## Rating Constants
**File**: [internal/models/rating.go](internal/models/rating.go)
### Rater Types```gotype RaterType string
const (    RaterDriver RaterType = "driver" // Driver giving rating    RaterPassenger RaterType = "passenger" // Passenger giving rating)```
---
## System Configuration Constants
**File**: [internal/constants/constants.go](internal/constants/constants.go)
### Driver Search Constants```goconst (    DefaultDriverSearchRadius = 5000 // 5km default search radius (meters)    FallbackDriverSearchRadius = 50000 // 50km fallback radius (meters)    MaxDriversPerRequest = 20 // Max drivers to notify per request)```
### Ride Distance Tolerance```goconst (    ArrivalDistanceTolerance = 50 // 50 meters from pickup    DestinationDistanceTolerance = 100 // 100 meters from destination)```
### Commission & Pricing```goconst (    PlatformCommissionRate = 0.20 // 20% commission    MinimumFare = 5.0 // $5 minimum fare    SurgeMultiplierDefault = 1.0 // No surge by default)```
### WebSocket Configuration```goconst (    WebSocketSendBufferSize = 256    WebSocketSendBufferWarning = 200 // 78% full warning    WebSocketWriteWait = 10 * time.Second    WebSocketPongWait = 60 * time.Second    WebSocketPingPeriod = (WebSocketPongWait * 9) / 10    WebSocketMaxMessageSize = 65536 // 64KB)```
### Rate Limiting```goconst (    // Global rate limits    GlobalRateLimitRPS = 100    GlobalRateLimitBurst = 20
    // OTP rate limits    OTPRateLimitRPS = 5    OTPRateLimitBurst = 2
    // Ride request rate limits    RideRequestRateLimitRPS = 10    RideRequestRateLimitBurst = 3)```
### Database & Pagination```goconst (    MaxPageSize = 100    DefaultPageSize = 20
    DatabaseMaxOpenConnections = 100    DatabaseMaxIdleConnections = 25    DatabaseConnectionMaxLifetime = time.Hour    DatabaseConnectionMaxIdleTime = 15 * time.Minute    SlowQueryThreshold = 100 * time.Millisecond)```
### OTP Configuration```goconst (    OTPLength = 6    OTPExpiryDuration = 5 * time.Minute    OTPMaxAttempts = 5)```
### JWT Configuration```goconst (    JWTExpiryDuration = 24 * time.Hour * 30 // 30 days    JWTRefreshThreshold = 7 * 24 * time.Hour // Refresh 7 days before expiry)```
### Payment Configuration```goconst (    PaymentTimeoutDuration = 5 * time.Minute    PaymentRetryAttempts = 3    PaymentRetryDelay = 2 * time.Second)```
### Cache TTL Configuration```goconst (    CacheUserProfileTTL = 5 * time.Minute    CacheDriverOnlineTTL = 30 * time.Second    CacheNearbyDriversTTL = 10 * time.Second    CacheRidePricingTTL = 1 * time.Hour    CacheOTPTTL = 5 * time.Minute)```
### Circuit Breaker Configuration```goconst (    CircuitBreakerMaxRequests = 3    CircuitBreakerInterval = 1 * time.Minute    CircuitBreakerTimeout = 30 * time.Second    CircuitBreakerFailureThreshold = 0.6 // 60%)```
### Logging Configuration```goconst (    LogRotationMaxSize = 100 // 100MB    LogRotationMaxBackups = 5    LogRotationMaxAge = 30 // days)```
### Health Check Configuration```goconst (    HealthCheckInterval = 30 * time.Second    HealthCheckTimeout = 5 * time.Second)```
### Admin Session Configuration```goconst (    AdminSessionTimeout = 12 * time.Hour    AdminSessionExtensionThreshold = 1 * time.Hour)```
### File Upload Configuration```goconst (    MaxUploadFileSize = 10 * 1024 * 1024 // 10MB    MaxProfileImageSize = 5 * 1024 * 1024 // 5MB    MaxDocumentSize = 10 * 1024 * 1024 // 10MB)```
### Allowed File Types (Variables)```govar AllowedImageTypes = []string{    "image/jpeg",    "image/jpg",    "image/png",    "image/webp",}
var AllowedDocumentTypes = []string{    "application/pdf",    "image/jpeg",    "image/jpg",    "image/png",}```
---
## API Version Constants
**File**: [internal/version/version.go](internal/version/version.go)
```goconst (    CurrentAPIVersion = "v1" // Current API version    APIPrefix = "/api" // API route prefix    FullAPIPath = "/api/v1" // Complete API path prefix)```
### Application Version (Variables)```govar (    Version = "1.0.0" // Application version    BuildTime = "Tue 07 Oct 2025 21:53:35" // Build timestamp    GitCommit = "unknown" // Git commit hash)```
---
## Usage Examples
### Checking User Role```goif user.Role == models.RoleDriver {    // Driver-specific logic}```
### Checking Ride Status```goif ride.Status == models.StatusCompleted {    // Process completed ride}```
### Validating Payment Method```goswitch payment.PaymentMethod {case models.PaymentMethodWallet:    // Process wallet paymentcase models.PaymentMethodTransferCard:    // Process card paymentcase models.PaymentMethodInCar:    // Handle cash payment}```
### Checking Transaction Type```goif transaction.Type == models.TransactionTypeRideEarning {    // Update driver earnings}```
### Using System Constants```goimport "taxiapp/internal/constants"
// Search for nearby driversradius := constants.DefaultDriverSearchRadiusdrivers := findNearbyDrivers(location, radius)
// Apply commissioncommission := fare * constants.PlatformCommissionRate```
---
## Summary
### Total Constants by Category:- **User & Roles**: 2 values- **Service Types**: 2 values- **Vehicle Types**: 6 values- **Ride Payment Methods**: 3 values- **Ride Status**: 6 values- **Payment Methods**: 5 values- **Payment Status**: 4 values- **Wallet Types**: 2 values- **Transaction Types**: 10 values- **Transaction Status**: 4 values- **Report Categories**: 14 values- **Report Status**: 4 values- **Report Severity**: 4 values- **Call Status**: 7 values- **WebSocket Messages**: 18 values- **Admin Roles**: 3 values- **Promo Types**: 2 values- **Promo Status**: 2 values- **Payment Types (Earnings)**: 2 values- **Payout Status**: 5 values- **Rater Types**: 2 values- **System Configuration**: 50+ values
### **Total**: 150+ constants across the application
---
**Generated**: 2024**Application**: SUPER-APP Taxi & Delivery Service**Version**: 1.0.0