# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

Sponsor.create([
  { name: "CAPES" },
  { name: "CNPq" },
  { name: "FAPERJ" },
])

ScholarshipType.create([
  { name: "Nota 10" },
  { name: "PROEX" },
  { name: "REUNI" },
  { name: "Individual" },
  { name: "Cota" },
  { name: "PEC-PG" },
  { name: "Projeto" },
  { name: "DAI" },
  { name: "DS" },
  { name: "COVID" },
  { name: "MAI" },
  { name: "PROPPI" },
])
