# Class Diagram Sistem Lapangku (Refactored)

Berikut adalah Class Diagram untuk sistem aplikasi Lapangku setelah dilakukan refactoring dengan prinsip OOP (Inheritance) dan standardisasi penamaan:

```mermaid
classDiagram
    class UserModel {
        +String uid
        +String email
        +String nama
        +String role
        +String phone
        +bool isVerified
        +fromFirestore()
        +toFirestore()
    }

    class MitraProfileModel {
        +String id
        +String businessName
        +String MitraName
        +int totalFields
        +int totalOrders
        +fromMap()
        +toMap()
    }

    class BaseFieldModel {
        <<abstract>>
        +String fieldId
        +String mitraId
        +String namaVenue
        +String namaLapangan
        +int hargaPerJam
    }

    class FieldModel {
        +String id
        +String kategori
        +String alamat
        +double latitude
        +double longitude
        +String deskripsi
        +bool isAktif
        +double ratingAvg
        +int totalUlasan
        +String fotoUtama
        +List~String~ fotoGaleri
        +List~String~ fasilitas
        +fromFirestore()
        +toFirestore()
    }

    class MitraFieldModel {
        +String id
        +String jenisLapangan
        +String deskripsi
        +String alamat
        +List~String~ photoUrls
        +List~String~ fasilitas
        +int hargaWeekend
        +String jamBuka
        +String jamTutup
        +bool isActive
        +DateTime createdAt
        +fromMap()
        +toMap()
        +copyWith()
    }

    class AdminFieldModel {
        +String namaMitra
        +String emailPemilik
        +String lokasi
        +String jenis
        +String statusVerifikasi
        +DateTime createdAt
    }

    class BookingModel {
        +String id
        +String bookingId
        +String fieldId
        +String userId
        +DateTime tanggal
        +List~String~ timeSlots
        +int totalBayar
        +String status
        +fromFirestore()
        +toFirestore()
    }

    class MitraScheduleModel {
        +String id
        +String fieldId
        +int dayOfWeek
        +String jamBuka
        +String jamTutup
        +bool isActive
        +String hari ~~getter~~
        +fromMap()
        +toMap()
        +copyWith()
    }

    class MitraReviewModel {
        +String id
        +String userName
        +int rating
        +String comment
        +DateTime date
    }

    class MitraRevenueModel {
        +int totalRevenue
        +int totalOrders
    }

    class MitraTransactionModel {
        +String id
        +String customerName
        +String fieldName
        +int amount
        +DateTime date
    }

    class AdminStats {
        +int totalUsers
        +int lapanganAktif
        +int pesananHariIni
        +int totalPendapatan
    }

    %% Inheritance
    BaseFieldModel <|-- FieldModel : extends
    BaseFieldModel <|-- MitraFieldModel : extends
    BaseFieldModel <|-- AdminFieldModel : extends

    %% Relationships
    UserModel "1" <|-- "0..1" MitraProfileModel : Extension ~Role = Mitra~
    UserModel "1" -- "*" BookingModel : Customer melakukan
    MitraProfileModel "1" -- "*" MitraFieldModel : Memiliki
    MitraFieldModel "1" -- "*" MitraScheduleModel : Memiliki jadwal
    FieldModel "1" -- "*" BookingModel : Dipesan dalam
    FieldModel "1" -- "*" MitraReviewModel : Memiliki ulasan
    BookingModel "1" -- "1" MitraTransactionModel : Menghasilkan
    MitraRevenueModel "1" *-- "*" MitraTransactionModel : Terdiri dari
```

---

## 📖 Penjelasan Class dan Model

Sistem ini menerapkan prinsip **OOP Inheritance** dan **standardisasi penamaan** untuk integrasi Firestore yang lebih bersih. Semua model lapangan kini mewarisi dari satu class abstrak `BaseFieldModel`.

### 1. Abstract Class: BaseFieldModel (BARU)
*   **`BaseFieldModel`**: Class abstrak yang menjadi parent dari semua model lapangan. Mendefinisikan 5 properti universal: `fieldId`, `mitraId`, `namaVenue`, `namaLapangan`, dan `hargaPerJam`.
*   Semua variasi penamaan ID pemilik (`idPemilik`, `MitraId`, `mitraUid`) kini distandarkan menjadi **`mitraId`** — konsisten dengan penamaan role di Firebase.
*   Semua variasi penamaan ID lapangan (`idLapangan`) kini distandarkan menjadi **`fieldId`**.

### 2. Model Pengguna (User & Profile)
*   **`UserModel`**: Entitas utama untuk semua pengguna (Customer, Mitra, Admin). Menyimpan `uid`, `email`, `nama`, dan `role`.
*   **`MitraProfileModel`**: Ekstensi profil khusus untuk `role = mitra`. Menyimpan detail bisnis, dokumen verifikasi, dan informasi bank.

### 3. Model Lapangan (Inheritance dari BaseFieldModel)
Ketiga model berikut kini melakukan **`extends BaseFieldModel`**, sehingga properti bersama tidak duplikat:
*   **`FieldModel`** → Tampilan **Customer**. Memuat rating, foto, lokasi, dan deskripsi.
*   **`MitraFieldModel`** → Dashboard **Mitra**. Memuat pengaturan harga, jadwal, dan status aktif.
*   **`AdminFieldModel`** → Dashboard **Admin**. Berisi ringkasan dan status verifikasi.

### 4. Model Transaksi (Booking & Pendapatan)
*   **`BookingModel`**: Inti transaksi yang menghubungkan Customer dan Lapangan.
*   **`MitraTransactionModel`**: Riwayat transaksi untuk dashboard Mitra.
*   **`MitraRevenueModel`**: Agregasi dari kumpulan transaksi Mitra.

### 5. Model Pendukung Lapangan
*   **`MitraScheduleModel`** (REFACTORED): Properti `hari` (String) diganti menjadi `dayOfWeek` (int: 1=Senin..7=Minggu). Tersedia getter `.hari` untuk backward-compat.
*   **`MitraReviewModel`**: Ulasan/rating dari Customer untuk suatu lapangan.

### 6. Model Admin
*   **`AdminStats`**: Statistik global sistem (total user, lapangan aktif, pesanan hari ini, pendapatan).

---

## 🔗 Penjelasan Relasi antar Class

1.  **`BaseFieldModel` ← `FieldModel`, `MitraFieldModel`, `AdminFieldModel`** (Inheritance):
    Ketiga model lapangan mewarisi properti bersama (`fieldId`, `mitraId`, `namaVenue`, `namaLapangan`, `hargaPerJam`) dari satu class abstrak.
2.  **`UserModel` (Customer) ↔ `BookingModel`** (One-to-Many):
    Satu customer dapat membuat banyak booking.
3.  **`UserModel` ↔ `MitraProfileModel`** (One-to-One):
    Jika `role = mitra`, maka memiliki satu `MitraProfileModel`.
4.  **`MitraProfileModel` ↔ `MitraFieldModel`** (One-to-Many):
    Satu mitra memiliki banyak lapangan.
5.  **`FieldModel` ↔ `BookingModel`** (One-to-Many):
    Satu lapangan dapat dipesan berkali-kali.
6.  **`MitraFieldModel` ↔ `MitraScheduleModel`** (One-to-Many):
    Satu lapangan memiliki banyak jadwal (per hari).
7.  **`FieldModel` ↔ `MitraReviewModel`** (One-to-Many):
    Satu lapangan memiliki banyak ulasan.
8.  **`BookingModel` ↔ `MitraTransactionModel`** (One-to-One):
    Satu booking menghasilkan satu transaksi pendapatan.
9.  **`MitraRevenueModel` ↔ `MitraTransactionModel`** (Composition):
    Laporan pendapatan terdiri atas kumpulan transaksi individual.

---

## 🔄 Ringkasan Perubahan Refactoring

| Aspek | Sebelum | Sesudah |
|---|---|---|
| **Inheritance** | Tidak ada parent class | `BaseFieldModel` (abstract) → 3 child classes |
| **ID Pemilik** | `idPemilik`, `MitraId`, `mitraUid` (inkonsisten) | `mitraId` (standar, konsisten dgn role Firebase) |
| **ID Lapangan** | `idLapangan` | `fieldId` (standar) + backward-compat getter |
| **Jadwal Hari** | `hari` (String: "Senin") | `dayOfWeek` (int: 1=Senin) + getter `.hari` |
| **Backward Compat** | - | Semua `fromMap`/`fromFirestore` membaca key lama dengan fallback `??` |
