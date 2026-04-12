using System;
using Microsoft.EntityFrameworkCore.Migrations;
using NetTopologySuite.Geometries;

#nullable disable

namespace H4H.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddPostGISAndGeolocationColumns : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // 1. Włącz PostGIS 
            migrationBuilder.Sql("CREATE EXTENSION IF NOT EXISTS postgis;");

            // 2. Dodaj kolumny Point do clients
            migrationBuilder.AddColumn<NetTopologySuite.Geometries.Point>(
                name: "address_point",
                table: "clients",
                type: "geography(Point, 4326)",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "address_geocoded_at",
                table: "clients",
                type: "timestamp without time zone",
                nullable: true);

            // 3. Dodaj kolumny Point do service_areas  
            migrationBuilder.AddColumn<NetTopologySuite.Geometries.Point>(
                name: "location",
                table: "service_areas",
                type: "geography(Point, 4326)",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "location_updated_at",
                table: "service_areas",
                type: "timestamp without time zone",
                nullable: true);

            // 4. Nowa tabela address_geocache 
            migrationBuilder.CreateTable(
                name: "address_geocache",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    address_hash = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    address = table.Column<string>(type: "text", nullable: false),
                    latitude = table.Column<decimal>(type: "numeric(10,8)", nullable: false),
                    longitude = table.Column<decimal>(type: "numeric(11,8)", nullable: false),
                    formatted_address = table.Column<string>(type: "text", nullable: true),
                    created_at = table.Column<DateTime>(type: "timestamp without time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_address_geocache", x => x.id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_address_geocache_address_hash",
                table: "address_geocache",
                column: "address_hash",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // Usuń nową tabelę
            migrationBuilder.DropTable(
                name: "address_geocache");

            // Usuń kolumny z clients
            migrationBuilder.DropColumn(
                name: "address_point",
                table: "clients");

            migrationBuilder.DropColumn(
                name: "address_geocoded_at",
                table: "clients");

            // Usuń kolumny z service_areas
            migrationBuilder.DropColumn(
                name: "location",
                table: "service_areas");

            migrationBuilder.DropColumn(
                name: "location_updated_at",
                table: "service_areas");

            // Wyłącz PostGIS
            migrationBuilder.Sql("DROP EXTENSION IF EXISTS postgis;");
        }
    }
}
