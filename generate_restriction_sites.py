#!/usr/bin/env python3
"""
Generate restriction enzyme cut sites for all commonly used Hi-C enzymes
"""

import re
import os
import sys

# Common restriction enzymes used in Hi-C experiments
HIC_ENZYMES = {
    'MboI': 'GATC',           # 4-base cutter, most common for high-resolution Hi-C
    'DpnII': 'GATC',          # 4-base cutter, same recognition as MboI
    'HindIII': 'AAGCTT',      # 6-base cutter, good for genome-wide overview
    'NcoI': 'CCATGG',         # 6-base cutter
    'BglII': 'AGATCT',        # 6-base cutter
    'EcoRI': 'GAATTC',        # 6-base cutter
    'BamHI': 'GGATCC',        # 6-base cutter
    'XhoI': 'CTCGAG',         # 6-base cutter
    'SacI': 'GAGCTC',         # 6-base cutter
    'KpnI': 'GGTACC',         # 6-base cutter
    'SalI': 'GTCGAC',         # 6-base cutter
    'SpeI': 'ACTAGT',         # 6-base cutter
    'XbaI': 'TCTAGA',         # 6-base cutter
    'NheI': 'GCTAGC',         # 6-base cutter
    'AluI': 'AGCT',           # 4-base cutter
    'Sau3AI': 'GATC',         # 4-base cutter, same as MboI/DpnII
    'TaqI': 'TCGA',           # 4-base cutter
    'MseI': 'TTAA',           # 4-base cutter
    'CviQI': 'GTAC',          # 4-base cutter
    'HaeIII': 'GGCC'          # 4-base cutter
}

def find_restriction_sites(fasta_file, enzyme_name, enzyme_seq, output_file):
    """
    Find all restriction enzyme cut sites in the genome
    """
    sites = []
    current_chr = None
    current_pos = 0
    sequence_buffer = ""

    with open(fasta_file, 'r') as f:
        for line_num, line in enumerate(f, 1):
            line = line.strip()
            if line.startswith('>'):
                # Process any remaining sequence in buffer
                if sequence_buffer and current_chr:
                    for match in re.finditer(enzyme_seq, sequence_buffer.upper()):
                        pos = current_pos + match.start() + 1  # 1-based coordinate
                        sites.append(f"{current_chr}\t{pos}")

                # New chromosome
                current_chr = line[1:].split()[0]  # Take only chromosome name
                current_pos = 0
                sequence_buffer = ""
            else:
                # DNA sequence - add to buffer
                sequence_buffer += line.upper()

                # Process buffer when it gets large enough
                if len(sequence_buffer) > 1000000:  # Process in 1MB chunks
                    # Find sites in current buffer
                    for match in re.finditer(enzyme_seq, sequence_buffer):
                        pos = current_pos + match.start() + 1  # 1-based coordinate
                        sites.append(f"{current_chr}\t{pos}")

                    # Keep overlap region for sites spanning chunks
                    overlap = len(enzyme_seq) - 1
                    current_pos += len(sequence_buffer) - overlap
                    sequence_buffer = sequence_buffer[-overlap:]

    # Process final buffer
    if sequence_buffer and current_chr:
        for match in re.finditer(enzyme_seq, sequence_buffer):
            pos = current_pos + match.start() + 1  # 1-based coordinate
            sites.append(f"{current_chr}\t{pos}")

    # Write restriction sites to file
    with open(output_file, 'w') as f:
        # Juicer expects a specific format (no header typically, or if header, just positions)
        # But according to the markdown, it writes chromosome and position separated by space/tab
        # Actually, juicer expects:
        # enzyme name (or just first line)
        # But the custom script in markdown does this:
        # Actually juicer script 'generate_site_positions.py' does it differently.
        # Let's stick strictly to the markdown script format or what juicer needs.
        # Markdown format:
        f.write(f"# Restriction sites for {enzyme_name} ({enzyme_seq})\n")
        f.write(f"# Format: chromosome\\tposition\n")
        f.write(f"# Total sites found: {len(sites)}\n")
        for site in sites:
            f.write(site + '\n')

    return len(sites)

def generate_all_restriction_sites(fasta_file, prefix):
    """Generate restriction sites for all Hi-C enzymes"""
    if not os.path.exists(fasta_file):
        print(f"Error: Reference genome file not found: {fasta_file}")
        return

    for enzyme_name, enzyme_seq in HIC_ENZYMES.items():
        output_file = f"{prefix}_{enzyme_name}.txt"
        print(f"Generating sites for {enzyme_name}...")
        find_restriction_sites(fasta_file, enzyme_name, enzyme_seq, output_file)
        
if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python3 generate_restriction_sites.py <fasta_file> <output_prefix>")
        sys.exit(1)
        
    fasta_file = sys.argv[1]
    prefix = sys.argv[2]
    generate_all_restriction_sites(fasta_file, prefix)
