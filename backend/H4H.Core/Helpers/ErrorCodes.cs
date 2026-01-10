using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace H4H.Core.Helpers
{
    public static class ErrorCodes
    {
        // Autoryzacja i uwierzytelnianie
        public const string InvalidCredentials = "AUTH_001";
        public const string EmailTaken = "AUTH_002";
        public const string UserNotFound = "AUTH_003";

        // Specjalista
        public const string SpecialistNotFound = "SPEC_001";
        public const string ServiceAlreadyExists = "SERV_001";
        public const string ServiceNotFound = "SERV_002";

        // Walidacja danych
        public const string ValidationError = "VAL_001";
    }
}
