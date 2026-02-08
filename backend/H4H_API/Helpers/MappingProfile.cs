using AutoMapper;
using H4H_API.DTOs.Client;
using H4H_API.DTOs.Specialist;
using H4H.Core.Models;
using H4H_API.DTOs.Appointments;

namespace H4H_API.Helpers
{
    public class MappingProfile : Profile
    {
        public MappingProfile()
        {
            // Mapowanie z modelu Client na ClientProfileDto
            CreateMap<Client, ClientProfileDto>()
                // Mapowanie Email z powiązanego obiektu User
                .ForMember(dest => dest.Email, opt => opt.MapFrom(src => src.User.Email))
                // Mapowanie PhoneNumber z powiązanego obiektu User
                .ForMember(dest => dest.PhoneNumber, opt => opt.MapFrom(src => src.User.PhoneNumber))
                // Mapowanie UpdatedAt z powiązanego obiektu User
                .ForMember(dest => dest.UpdatedAt, opt => opt.MapFrom(src => src.User.UpdatedAt));

            // Mapowanie dla aktualizacji - ClientUpdateDto na Client
            CreateMap<ClientUpdateDto, Client>();

            // Mapowanie dla aktualizacji - ClientUpdateDto na User
            CreateMap<ClientUpdateDto, User>();

            //Mapowanie z modelu Specialist na SpecialistDto
            CreateMap<Specialist, SpecialistDto>()
                .ForMember(dest => dest.IsVerified, opt => opt.MapFrom(src => src.VerificationStatus == "verified"))
                .ForMember(dest => dest.AverageRating, opt => opt.MapFrom(src => (decimal)src.AverageRating));
            
            // Mapowanie z modelu SpecialistService na SpecialistServiceDto
            CreateMap<Appointment, AppointmentDto>()
                .ForMember(dest => dest.ClientName, opt => opt.MapFrom(src => src.Client != null ? $"{src.Client.FirstName} {src.Client.LastName}" : null));

            // Mapowanie z modelu Appointment na AppointmentDto, uwzględniające nazwy klienta, specjalisty i usługi
            CreateMap<Appointment, AppointmentDto>()
                .ForMember(dest => dest.ClientName, opt => opt.MapFrom(src =>
                    src.Client != null ? $"{src.Client.FirstName} {src.Client.LastName}" : "Brak danych"))
                .ForMember(dest => dest.SpecialistName, opt => opt.MapFrom(src =>
                    src.Specialist != null ? $"{src.Specialist.FirstName} {src.Specialist.LastName}" : "Nieprzypisany"))
                .ForMember(dest => dest.ServiceName, opt => opt.MapFrom(src =>
                    src.SpecialistService != null && src.SpecialistService.ServiceType != null
                    ? src.SpecialistService.ServiceType.Name : "Usługa nieznana"));

            // Mapowanie z modelu ServiceRequest na ServiceRequestDto, uwzględniające nazwę typu usługi
            CreateMap<ServiceRequest, ServiceRequestDto>()
                .ForMember(dest => dest.ServiceTypeName, opt => opt.MapFrom(src => src.ServiceType.Name));
        }
    }
}
