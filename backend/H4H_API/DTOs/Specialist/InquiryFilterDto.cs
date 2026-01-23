namespace H4H_API.DTOs.Specialist
{
    public class InquiryFilterDto
    {
        public string? PatientName { get; set; } // Szukanie po imieniu/nazwisku
        public DateTime? DateFrom { get; set; }
        public DateTime? DateTo { get; set; }

        public string? ServiceName { get; set; }

        // Do obsluzenia gdy w bazie pojawia sie wspolrzedne geograficzne
        public int? MaxDistanceKm { get; set; }
    }
}
