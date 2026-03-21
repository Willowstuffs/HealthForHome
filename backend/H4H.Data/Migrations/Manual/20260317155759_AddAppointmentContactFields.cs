using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace H4H.Data.Migrations.Manual
{
    /// <inheritdoc />
    public partial class AddAppointmentContactFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "contact_email",
                table: "appointments",
                type: "character varying(150)",
                maxLength: 150,
                nullable: false,
                defaultValue: "");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "contact_email",
                table: "appointments");
        }
    }
}
