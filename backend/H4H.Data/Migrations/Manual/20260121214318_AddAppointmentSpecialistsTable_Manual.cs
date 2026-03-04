using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace H4H.Data.Migrations.Manual
{
    /// <inheritdoc />
    public partial class AddAppointmentSpecialistsTable_Manual : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // 1. Sprawdź czy appointments_specialists istnieje, jeśli nie - stwórz
            migrationBuilder.Sql(@"
                DO $$ 
                BEGIN 
                    -- Sprawdź czy tabela istnieje
                    IF NOT EXISTS (
                        SELECT 1 
                        FROM information_schema.tables 
                        WHERE table_name = 'appointments_specialists'
                        AND table_schema = 'public'
                    ) THEN
                        -- Tabela NIE istnieje - stwórz
                        CREATE TABLE appointments_specialists (
                            id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
                            appointment_id uuid NOT NULL REFERENCES appointments(id) ON DELETE CASCADE,
                            specialist_id uuid NOT NULL REFERENCES specialists(id) ON DELETE CASCADE,
                            created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
                            UNIQUE (appointment_id, specialist_id)
                        );
                        
                        -- Stwórz indeksy
                        CREATE INDEX ix_appointments_specialists_appointment 
                            ON appointments_specialists(appointment_id);
                            
                        CREATE INDEX ix_appointments_specialists_specialist 
                            ON appointments_specialists(specialist_id);
                            
                        RAISE NOTICE 'Tabela appointments_specialists została stworzona';
                    ELSE
                        RAISE NOTICE 'Tabela appointments_specialists już istnieje';
                    END IF;
                END $$;
            ");

            // 2. Sprawdź czy selected_specialist_id istnieje, jeśli nie - dodaj
            migrationBuilder.Sql(@"
                DO $$ 
                BEGIN 
                    -- Sprawdź czy kolumna istnieje
                    IF NOT EXISTS (
                        SELECT 1 
                        FROM information_schema.columns 
                        WHERE table_name = 'appointments' 
                        AND column_name = 'selected_specialist_id'
                    ) THEN
                        -- Kolumna NIE istnieje - dodaj
                        ALTER TABLE appointments 
                        ADD COLUMN selected_specialist_id uuid REFERENCES specialists(id);
                        
                        -- Stwórz indeks
                        CREATE INDEX ix_appointments_selected_specialist 
                            ON appointments(selected_specialist_id);
                            
                        RAISE NOTICE 'Kolumna selected_specialist_id została dodana';
                    ELSE
                        RAISE NOTICE 'Kolumna selected_specialist_id już istnieje';
                        
                        -- Sprawdź czy ma klucz obcy
                        IF NOT EXISTS (
                            SELECT 1 
                            FROM information_schema.table_constraints tc
                            JOIN information_schema.key_column_usage kcu 
                                ON tc.constraint_name = kcu.constraint_name
                            WHERE tc.table_name = 'appointments' 
                            AND tc.constraint_type = 'FOREIGN KEY'
                            AND kcu.column_name = 'selected_specialist_id'
                        ) THEN
                            -- Dodaj brakujący klucz obcy
                            ALTER TABLE appointments 
                            ADD CONSTRAINT fk_appointments_selected_specialist 
                                FOREIGN KEY (selected_specialist_id) 
                                REFERENCES specialists(id);
                                
                            RAISE NOTICE 'Dodano brakujący klucz obcy dla selected_specialist_id';
                        END IF;
                    END IF;
                END $$;
            ");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
           
            // Nie chcemy usuwać czegoś co mogło istnieć przed migracją

            migrationBuilder.Sql(@"
                RAISE NOTICE 'Migracja Down: Nie usuwam istniejących tabel/kolumn';
            ");
        }
    }
}