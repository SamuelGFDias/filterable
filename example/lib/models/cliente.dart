class Cliente implements Comparable<Cliente> {
  final int id;
  final String nome;

  Cliente(this.id, this.nome);

  @override
  int compareTo(Cliente other) {
    return id.compareTo(other.id);
  }
}