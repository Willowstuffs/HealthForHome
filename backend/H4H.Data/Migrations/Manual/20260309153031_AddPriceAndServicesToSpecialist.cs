using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace H4H.Data.Migrations.Manual
{
    /// <inheritdoc />
    public partial class AddPriceAndServicesToSpecialist : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<decimal>(
                name: "price",
                table: "appointments_specialists",
                type: "numeric(10,2)",
                precision: 10,
                scale: 2,
                nullable: true);

            migrationBuilder.AddColumn<List<Guid>>(
                name: "service_type_ids",
                table: "appointments_specialists",
                type: "uuid[]",
                nullable: false,
                defaultValueSql: "'{}'");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "price",
                table: "appointments_specialists");

            migrationBuilder.DropColumn(
                name: "service_type_ids",
                table: "appointments_specialists");
        }
    }
}
