using AutoMapper;
using H4H_API.DTOs.Client;
using H4H.Core.Models;

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
        }
    }
}
