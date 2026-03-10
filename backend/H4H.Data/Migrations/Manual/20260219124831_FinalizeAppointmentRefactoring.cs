using System;
using Microsoft.EntityFrameworkCore.Migrations;
using NetTopologySuite.Geometries;

#nullable disable

namespace H4H.Data.Migrations.Manual
{
    /// <inheritdoc />
    public partial class FinalizeAppointmentRefactoring : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // 1. Usuwamy starą tabelę
            migrationBuilder.DropTable(
                name: "service_requests");

            // 2. RĘCZNIE DODAJEMY BRAKUJĄCE KOLUMNY DO APPOINTMENTS
            migrationBuilder.AddColumn<Point>(
                name: "location",
                table: "appointments",
                type: "geography(Point, 4326)",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "service_type_id",
                table: "appointments",
                type: "uuid",
                nullable: true);

            // 3. DODAJEMY KLUCZ OBCY DLA KATEGORII USŁUGI
            migrationBuilder.AddForeignKey(
                name: "FK_appointments_service_types_service_type_id",
                table: "appointments",
                column: "service_type_id",
                principalTable: "service_types",
                principalColumn: "id",
                onDelete: ReferentialAction.SetNull);

            // 4. INDEKS DLA SZYBSZEGO WYSZUKIWANIA KATEGORII
            migrationBuilder.CreateIndex(
                name: "IX_appointments_service_type_id",
                table: "appointments",
                column: "service_type_id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "service_requests",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    client_id = table.Column<Guid>(type: "uuid", nullable: true),
                    service_type_id = table.Column<Guid>(type: "uuid", nullable: false),
                    address = table.Column<string>(type: "text", nullable: false),
                    contact_name = table.Column<string>(type: "text", nullable: false),
                    created_at = table.Column<DateTime>(type: "timestamp without time zone", nullable: false),
                    date_from = table.Column<DateTime>(type: "timestamp without time zone", nullable: false),
                    date_to = table.Column<DateTime>(type: "timestamp without time zone", nullable: false),
                    description = table.Column<string>(type: "text", nullable: false),
                    email = table.Column<string>(type: "text", nullable: false),
                    location = table.Column<Point>(type: "geography(Point, 4326)", nullable: false),
                    max_price = table.Column<decimal>(type: "numeric", nullable: true),
                    phone_number = table.Column<string>(type: "text", nullable: false),
                    status = table.Column<string>(type: "text", nullable: false, defaultValue: "open"),
                    updated_at = table.Column<DateTime>(type: "timestamp without time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_service_requests", x => x.id);
                    table.ForeignKey(
                        name: "FK_service_requests_clients_client_id",
                        column: x => x.client_id,
                        principalTable: "clients",
                        principalColumn: "id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_service_requests_service_types_service_type_id",
                        column: x => x.service_type_id,
                        principalTable: "service_types",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_service_requests_client_id",
                table: "service_requests",
                column: "client_id");

            migrationBuilder.CreateIndex(
                name: "IX_service_requests_service_type_id",
                table: "service_requests",
                column: "service_type_id");
        }
    }
}
