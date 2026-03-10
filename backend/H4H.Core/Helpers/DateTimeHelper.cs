using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace H4H.Core.Helpers
{
    public static class DateTimeHelper
    {
        public static DateTime NowUnspecified => DateTime.SpecifyKind(DateTime.Now, DateTimeKind.Unspecified);
        public static DateTime UtcToUnspecified(DateTime utcTime) =>
            DateTime.SpecifyKind(utcTime.ToLocalTime(), DateTimeKind.Unspecified);
    }
}
